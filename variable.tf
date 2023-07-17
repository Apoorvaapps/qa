variable "resource_group_location" {
   description = "Location of the resource group"
    type        = string 
}

variable "resource_group_name" {
    description = "name of the resource group"
    type        = string
}

variable "subnet_prefix" {
  type = map(any)
  default = {
    subnet-1 = {
      ip                 = ["10.0.1.0/24"]
      service_delegation = true
      name               = "subnet-1"
    } 
    subnet-2 = {
      ip                 = ["10.0.2.0/24"]
      service_delegation = false
      name               = "subnet-2"
    }
   }
}

variable "admin_username" {
  type        = string
  description = "The administrator username of the SQL logical server."
  #default    = "vmuser123"
}

variable "admin_password" {
  type        = string
  description = "The administrator password of the SQL logical server."
  sensitive   = true
  #default    = "password@768954"
}

variable "administrator_login" {
  type        = string
  description = "The administrator username of the SQL logical server."
  #default     = "postgreadmin123"
}

variable "administrator_password" {
  type        = string
  description = "The administrator password of the SQL logical server."
  sensitive   = true
  #default     = "password@14532"
}