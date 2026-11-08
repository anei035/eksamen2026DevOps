variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "kandidatnummer" {
  type    = string
  default = "42"
}

variable "image_tag" {
  type    = string
  default = "latest"
}
variable "alarm_email" {
  type    = string
  default = "kandidat42.pgr301@gmail.com"
}