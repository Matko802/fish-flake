#include "plugin.hpp"

#include "output_power.hpp"

void OutputPowerPlugin::registerTypes(const char* uri) {
  qmlRegisterType<OutputPower>(uri, 1, 0, "OutputPower");
}