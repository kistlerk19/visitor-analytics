# State protection marker
resource "terraform_data" "deployment_marker" {
  input = {
    timestamp = timestamp()
    image_tag = var.image_tag
    enable_dr = var.enable_dr
  }
}