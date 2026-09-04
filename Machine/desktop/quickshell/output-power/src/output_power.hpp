#pragma once

#include <QObject>

// Native output power control for Quickshell.
//
// Implements the wlr-output-power-management-unstable-v1 client role directly
// (no external binary like wlopm): binds zwlr_output_power_manager_v1 from the
// running compositor's Wayland registry and drives each wl_output's power mode.
class OutputPower : public QObject {
  Q_OBJECT

public:
  explicit OutputPower(QObject* parent = nullptr);
  ~OutputPower() override;

  // Turn every output on (true) or off (false).
  Q_INVOKABLE void setAllPower(bool on) const;
};