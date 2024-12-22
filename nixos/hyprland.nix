{ config, pkgs, ...}:                                                                
{                                                                                 
  environment.systemPackages = with pkgs; [                                       
    dunst                                                                            
    kitty                                                                            
    wl-clipboard
    capitaine-cursors 
    libnotify                                                                        
    networkmanagerapplet                                                             
    rofi-wayland                                                                     
    swww                                                                             
    waybar   
  ];                                                                                 

  programs.hyprland.enable = true;
  programs.hyprland.xwayland.enable = true;

  environment.sessionVariables = {                                                   
    NIXOS_OZONE_WL = "1";                                                            
    WLR_NO_HARDWARE_CURSORS = "1";
};                                                                                 
                                                                                     
  fonts.packages = with pkgs; [                                                         
    font-awesome                                                                     
    nerdfonts                                                                        
  ];                                                                                 
                                                                                     
  xdg.portal.enable = true;                                                          
  xdg.portal.extraPortals = with pkgs; [                                             
    xdg-desktop-portal-wlr                                                           
  ];  
}
