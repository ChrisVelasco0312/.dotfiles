require('gitblame').setup {
  enabled = true,
  message_template = "󰅶 <date> | 󰀬 <author> | 󰊢 <<sha>> | 󰞇 <summary>",
  date_format = "%m-%d-%Y %H:%M:%S",
  display_virtual_text = 0
}
