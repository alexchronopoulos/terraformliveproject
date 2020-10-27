variable "namespace" {
    type = string
}

variable "branch" {
    type = string
}

variable "task" {
    type = string
}

variable "ecs_cluster" {
    type = string
}

variable "ecs_service" {
    type = string
}

variable "alb" {
    type = any
}