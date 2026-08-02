{ ... }:
{
  services.beszel.agent = {
    enable = true;
    environment = {
      PORT = "45876";
      KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHPF8VerHU8Y0nq8YruGK1QKRkTWisPgWa/YM5IJVc39";
    };
  };
}
