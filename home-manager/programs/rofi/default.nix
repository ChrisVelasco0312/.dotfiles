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
        background-color: #151515;
        text-color: #ffffff;
        border-color: #ffffff;
        separatorcolor: #333333;
        selected-normal-background: #ffffff;
        selected-normal-foreground: #151515;
        normal-background: #151515;
        normal-foreground: #ffffff;
        alternate-normal-background: #151515;
        alternate-normal-foreground: #ffffff;
    }
    
    window {
        background-color: @background-color;
        border: 1;
        border-color: @border-color;
        border-radius: 0;
        padding: 8;
    }
    
    mainbox {
        border: 0;
        padding: 4;
        background-color: transparent;
        children: [inputbar, message, mode-switcher, listview];
        spacing: 10px;
    }
    
    message {
        padding: 5px;
        border-radius: 3px;
        background-color: @alternate-normal-background;
        border: 1px;
        border-color: @border-color;
    }
    textbox {
        text-color: @text-color;
    }
    
    inputbar {
        children: [prompt, entry];
        background-color: #252525;
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
        placeholder-color: #555555;
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

    mode-switcher {
        spacing: 0;
    }

    button {
        padding: 10px;
        background-color: @alternate-normal-background;
        text-color: @alternate-normal-foreground;
        vertical-align: 0.5; 
        horizontal-align: 0.5;
    }

    button selected {
        background-color: @selected-normal-background;
        text-color: @selected-normal-foreground;
    }
  '';
}
