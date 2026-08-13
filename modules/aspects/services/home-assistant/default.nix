{ den, ... }:
{
  den.aspects.services.home-assistant = {
    includes = [
      # Core HA + automations
      den.aspects.services.home-assistant.home-assistant
      # Satellite services
      den.aspects.services.home-assistant.esphome
      den.aspects.services.home-assistant.matter
      den.aspects.services.home-assistant.mqtt
      den.aspects.services.home-assistant.music-assistant
      den.aspects.services.home-assistant.openthread
      den.aspects.services.home-assistant.zigbee2mqtt
    ];
  };
}
