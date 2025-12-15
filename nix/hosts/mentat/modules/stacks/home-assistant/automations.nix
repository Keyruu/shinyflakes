_: {
  environment.etc."stacks/home-assistant/config/automations.yaml" = # yaml
    ''
      - id: '1739042540563'
        alias: Bewegung im Gang
        description: ""
        use_blueprint:
          path: Blackshome/sensor-light.yaml
          input:
            motion_trigger:
            - binary_sensor.gangbewegungsmelder_1_occupancy
            light_switch:
              entity_id: switch.ganglichtschalter
            time_delay: 0.5
      - id: '1739043545982'
        alias: Gang Bewegung Custom
        description: ""
        triggers:
        - trigger: state
          entity_id:
          - binary_sensor.gangbewegungsmelder_1_occupancy
        conditions: []
        actions:
        - if:
          - type: is_occupied
            condition: device
            device_id: 356156948196d2ef56d8c50bcdcaadf1
            entity_id: 5de359488b86b28ea041159cdb615a82
            domain: binary_sensor
          then:
          - type: turn_on
            device_id: de1ca7d6be662912d99f734842988aa5
            entity_id: cc33e6abd5c3ade89e3eed1e4bda017a
            domain: switch
        - if:
          - type: is_not_occupied
            condition: device
            device_id: 356156948196d2ef56d8c50bcdcaadf1
            entity_id: 5de359488b86b28ea041159cdb615a82
            domain: binary_sensor
          then:
          - type: turn_off
            device_id: de1ca7d6be662912d99f734842988aa5
            entity_id: cc33e6abd5c3ade89e3eed1e4bda017a
            domain: switch
        mode: single
      - id: '1739467660538'
        alias: Bürolichtschalter
        description: ""
        triggers:
        - trigger: state
          entity_id:
          - event.burolichtschalter_action
        conditions: []
        actions:
        - type: toggle
          device_id: d9cf39b9856d9d3dc7b6d141064df7cd
          entity_id: ef8906647870217353ba9a531b00f5c0
          domain: light
        mode: single
      - id: '1746478270122'
        alias: Voice Box Schlafzimmer Screen
        description: ""
        triggers:
        - trigger: state
          entity_id:
          - assist_satellite.voice_box_schlafzimmer_assist_satellite
        conditions: []
        actions:
        - choose:
          - conditions:
            - condition: state
              entity_id: assist_satellite.voice_box_schlafzimmer_assist_satellite
              state: idle
            sequence:
            - type: turn_off
              device_id: 92591ac672dbc2eca839f438f5912ba1
              entity_id: 15ac7c83b6db556afef187239c774aaf
              domain: light
          - conditions:
            - condition: state
              entity_id: assist_satellite.voice_box_schlafzimmer_assist_satellite
              state: listening
            sequence:
            - type: turn_on
              device_id: 92591ac672dbc2eca839f438f5912ba1
              entity_id: 15ac7c83b6db556afef187239c774aaf
              domain: light
        mode: single
      - id: '1747858593266'
        alias: Lokale Music Assistant Kontrolle
        description: ""
        use_blueprint:
          path: music-assistant/mass_assist_blueprint_de.yaml
          input:
            default_player_entity_id_input: media_player.voice_wohnbereich_media_player_2
      - id: '1751654439428'
        alias: Klingel
        description: ""
        triggers:
        - trigger: state
          entity_id:
          - event.vordereingang_intercom_ding
          alias: Wenn Klingel gedrückt wird
        conditions: []
        actions:
        - action: assist_satellite.announce
          metadata: {}
          data:
            message: Jemand ist an der Tür!
            preannounce: true
          target:
            device_id:
            - 92591ac672dbc2eca839f438f5912ba1
            - d62ab7c7bfc4a9ee3aa9b24ea3903118
            - 2b0570dc0ab32af74f9f97afb83333c0
          alias: Auf den Voice Assistants announcen
        - alias: Set up variables for the actions
          variables:
            action_open: '{{ "OPEN_" ~ context.id }}'
            action_no: '{{ "NO_" ~ context.id }}'
        - alias: Über Klingel informieren
          action: notify.mobile_app_mobiltelefon
          data:
            message: Jemand ist an der Tür!
            data:
              actions:
              - action: '{{ action_open }}'
                title: Öffnen
              - action: '{{ action_no }}'
                title: Verpiss dich!
            title: Klingel
        - alias: Über Klingel informieren
          action: notify.mobile_app_moto_g54_5g
          data:
            message: Jemand ist an der Tür!
            data:
              actions:
              - action: '{{ action_open }}'
                title: Öffnen
              - action: '{{ action_no }}'
                title: Verpiss dich!
            title: Klingel
        - alias: Auf Antwort warten
          wait_for_trigger:
          - event_type: mobile_app_notification_action
            event_data:
              action: '{{ action_open }}'
            trigger: event
          - event_type: mobile_app_notification_action
            event_data:
              action: '{{ action_no }}'
            trigger: event
        - if:
          - condition: template
            value_template: '{{ wait.trigger.event.data.action == action_open }}'
          then:
          - action: button.press
            metadata: {}
            data: {}
            target:
              entity_id: button.vordereingang_intercom_open_door
          alias: Wenn open dann mach auf
        mode: single
      - id: '1755000000000'
        alias: Fenster offen Warnung
        description: ""
        triggers:
        - type: opened
          device_id: e5e1f3503642402b47659f9911a50a15
          entity_id: ba2a0212b67ba4c34a809567039cf014
          domain: binary_sensor
          trigger: device
          alias: Bad Fenster
        - type: opened
          device_id: 4c931f4681749d66f9092763ff64da3a
          entity_id: e60b39fe2deee4a3ca2a831230756d67
          domain: binary_sensor
          trigger: device
          alias: Büro Fenster
        - type: opened
          device_id: d406624a301cb3f2a9ebdc5e019982e9
          entity_id: 62c77b3f227117e29cae438fad849d0d
          domain: binary_sensor
          trigger: device
          alias: Schlafzimmer Fenster
        - type: opened
          device_id: 450d7b82969bb198b371d3b1c1e7ec80
          entity_id: f82607de58e2b44328ed33c546f37937
          domain: binary_sensor
          trigger: device
          alias: Wohnbereich Fenster
        conditions: []
        actions:
        - alias: Variablen für offene Fenster erstellen
          variables:
            windows:
              ba2a0212b67ba4c34a809567039cf014: Bad
              e60b39fe2deee4a3ca2a831230756d67: Büro
              62c77b3f227117e29cae438fad849d0d: Schlafzimmer
              f82607de58e2b44328ed33c546f37937: Wohnbereich
            open_windows: >-
              {% set ns = namespace(windows=[]) %}
              {% for entity_id, name in windows.items() %}
                {% if is_state('binary_sensor.' ~ entity_id, 'on') %}
                  {% set ns.windows = ns.windows + [name] %}
                {% endif %}
              {% endfor %}
              {{ ns.windows | join(', ') }}
            window_count: >-
              {% set ns = namespace(count=0) %}
              {% for entity_id in windows.keys() %}
                {% if is_state('binary_sensor.' ~ entity_id, 'on') %}
                  {% set ns.count = ns.count + 1 %}
                {% endif %}
              {% endfor %}
              {{ ns.count }}
            message: >-
              {% if window_count | int == 1 %}
                Hey! Hast du den Arsch offen wie das {{ open_windows }} Fenster? Mach's zu!
              {% else %}
                Hey! Hast du den Arsch offen? {{ window_count }} Fenster sind auf: {{ open_windows }}! Mach's zu!
              {% endif %}
        - action: assist_satellite.announce
          metadata: {}
          data:
            message: '{{ message }}'
            preannounce: true
          target:
            device_id:
            - 92591ac672dbc2eca839f438f5912ba1
            - d62ab7c7bfc4a9ee3aa9b24ea3903118
            - 2b0570dc0ab32af74f9f97afb83333c0
          alias: Auf den Voice Assistants announcen
        - alias: Über offenes Fenster informieren
          action: notify.mobile_app_mobiltelefon
          data:
            message: 'Offene Fenster: {{ open_windows }}'
            title: '{{ window_count }} Fenster offen!'
        - alias: Über offenes Fenster informieren
          action: notify.mobile_app_moto_g54_5g
          data:
            message: 'Offene Fenster: {{ open_windows }}'
            title: '{{ window_count }} Fenster offen!'
        mode: single
    '';
}
