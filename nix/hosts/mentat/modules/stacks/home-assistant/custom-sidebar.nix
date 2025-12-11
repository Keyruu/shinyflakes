_:
{
  environment.etc."stacks/home-assistant/config/configuration.yaml".text = # yaml
    ''
      default_path: "/dashboard-main"
      order:
        - item: overview
          hide: true
        - item: dashboard-main
          order: 0
        - item: dashboard-areas
          order: 1
        - item: dashboard-tv
          order: 2
        - item: dashboard-homepage
          order: 3
        - item: energy
          order: 4
        - item: todo
          order: 5
        - item: map
          order: 6
        - item: logbook
          order: 6
        - item: history
          order: 7
        - item: media-browser
          order: 8
        - item: hacs
          order: 9
        - item: dashboard-esphome
          order: 10
        - item: music-assistant
          order: 11
        - item: dashboard-zigbee2mqtt
          order: 12
        - item: matter-hub
          order: 13
    '';
}
