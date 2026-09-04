#include "output_power.hpp"

#include <QList>
#include <wayland-client.h>

#include "wlr-output-power-management-unstable-v1-client-protocol.h"

namespace {

struct RegistryContext {
  QList<wl_output*> outputs;
  zwlr_output_power_manager_v1* manager = nullptr;
};

static void registryGlobal(void* data, wl_registry* registry, uint32_t id,
                           const char* interface, uint32_t version) {
  auto* ctx = static_cast<RegistryContext*>(data);
  if (qstrcmp(interface, wl_output_interface.name) == 0) {
    ctx->outputs.append(static_cast<wl_output*>(
        wl_registry_bind(registry, id, &wl_output_interface, qMin<quint32>(version, 4u))));
  } else if (qstrcmp(interface, zwlr_output_power_manager_v1_interface.name) == 0) {
    ctx->manager = static_cast<zwlr_output_power_manager_v1*>(
        wl_registry_bind(registry, id, &zwlr_output_power_manager_v1_interface, 1));
  }
}

static void registryRemove(void*, wl_registry*, uint32_t id) {
  qWarning("OutputPower: registry object %u removed", id);
}

const wl_registry_listener s_registryListener = {registryGlobal, registryRemove};

}  // namespace

OutputPower::OutputPower(QObject* parent) : QObject(parent) {}

OutputPower::~OutputPower() = default;

void OutputPower::setAllPower(bool on) const {
  // Connect our own client socket to the same compositor (via WAYLAND_DISPLAY),
  // rather than reaching into QGuiApplication's Wayland integration.
  wl_display* display = wl_display_connect(nullptr);
  if (!display) {
    qWarning("OutputPower: could not connect to Wayland display (WAYLAND_DISPLAY?)");
    return;
  }

  RegistryContext ctx;
  wl_registry* registry = wl_display_get_registry(display);
  if (!registry) {
    wl_display_disconnect(display);
    return;
  }
  wl_registry_add_listener(registry, &s_registryListener, &ctx);
  wl_display_roundtrip(display);

  if (!ctx.manager) {
    qWarning("OutputPower: compositor does not offer zwlr_output_power_manager_v1");
  } else {
    const auto mode = on ? ZWLR_OUTPUT_POWER_V1_MODE_ON : ZWLR_OUTPUT_POWER_V1_MODE_OFF;
    for (wl_output* output : ctx.outputs) {
      auto* power = zwlr_output_power_manager_v1_get_output_power(ctx.manager, output);
      zwlr_output_power_v1_set_mode(power, mode);
      wl_display_roundtrip(display);
      zwlr_output_power_v1_destroy(power);
    }
  }
  wl_display_flush(display);
  wl_registry_destroy(registry);
  wl_display_disconnect(display);
}