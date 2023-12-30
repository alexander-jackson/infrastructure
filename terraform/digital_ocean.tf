resource "digitalocean_project" "blackboards" {
  name        = "blackboards"
  purpose     = "Service or API"
  environment = "Production"
  is_default  = true

  resources = []
}
