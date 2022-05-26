variable "genesys_email_domain" {
  type        = string
  description = "The name of the domain.  This is used to help build the email route"
}

variable "genesys_email_domain_region" {
  type        = string
  description = "Region Name for the email"
}

variable "genesys_email_flow" {
  type        = string
  description = "Name of the Email Flow to configure for the route"
}

