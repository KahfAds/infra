locals {
  file_name = "/etc/cron.d/${var.cron_job.name}"
  command = "${var.cron_job.schedule} ${var.cron_job.run_as_user} ${var.cron_job.command}"
}

resource "null_resource" "create_cronjob" {
  provisioner "remote-exec" {
    inline = [
        "echo '${local.command}' | sudo tee ${local.file_name} > /dev/null",
        "sudo chmod 644 ${local.file_name}",
        "sudo systemctl restart cron || sudo service cron restart"
    ]
  }

  connection {
    host        = var.ssh.host
    user        = var.ssh.user
    private_key = var.ssh.private_key_pem
  }
}

# Variables
variable "ssh" {
  type = object({
    user       = string
    private_key_pem = string
    host      = string
  })
}

variable "cron_job" {
  type = object({
    name = string
    command = string
    run_as_user = string
    schedule = string
  })
}
