{ config, pkgs, ... }:
{
  home.packages = [ pkgs.rofi ];
  
  home.file.".config/rofi/config.rasi".text = ''
    configuration {
        font: "monospace 14";
        modi: "drun,run";
        show-icons: true;
        display-drun: "Apps";
        display-run: "Run";
        terminal: "${pkgs.kitty}/bin/kitty";
    }
    
    * {
        font: "monospace 14";
        background-color: #1e1e2e;
        text-color: #cdd6f4;
        border-color: #89b4fa;
        separatorcolor: #6c7086;
        selected-normal-background: #89b4fa;
        selected-normal-foreground: #1e1e2e;
        normal-background: #1e1e2e;
        normal-foreground: #cdd6f4;
        alternate-normal-background: #1e1e2e;
        alternate-normal-foreground: #cdd6f4;
    }
    
    window {
        background-color: @background-color;
        border: 2;
        border-color: @border-color;
        border-radius: 8;
        padding: 8;
    }
    
    mainbox {
        border: 0;
        padding: 4;
        background-color: transparent;
    }
    
    inputbar {
        children: [prompt, entry];
        background-color: #313244;
        text-color: @text-color;
        padding: 8;
        border-radius: 4;
        margin: 0 0 8 0;
    }
    
    prompt {
        background-color: transparent;
        text-color: @text-color;
        padding: 0 8 0 0;
    }
    
    entry {
        background-color: transparent;
        text-color: @text-color;
        placeholder: "Search...";
        placeholder-color: #6c7086;
    }
    
    listview {
        background-color: @background-color;
        spacing: 0;
        scrollbar: false;
        border: 0;
    }
    
    element {
        background-color: @background-color;
        text-color: @text-color;
        padding: 8;
        border: 0;
    }
    
    element normal.normal {
        background-color: @background-color;
        text-color: @text-color;
    }
    
    element alternate.normal {
        background-color: @background-color;
        text-color: @text-color;
    }
    
    element selected.normal {
        background-color: @selected-normal-background;
        text-color: @selected-normal-foreground;
        border-radius: 4;
    }
    
    element-icon {
        size: 24;
        margin: 0 8 0 0;
        background-color: transparent;
    }
    
    element-text {
        background-color: transparent;
        text-color: inherit;
    }
  '';
}
