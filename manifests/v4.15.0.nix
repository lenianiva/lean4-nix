{
  tag = "v4.15.0";
  rev = "11651562caae0a0b3973811508db2ab8903d3854";

  toolchain = {
    aarch64-linux.hash = "sha256-QFeUrhvW96/APC8ZPCM8FnwsfGpaBt420DW8r3Zv9iY=";
    x86_64-linux.hash = "sha256-r3GiVpqfaDN94kNIKbMAjNjjLENunLa9jISiwro1hck=";
    x86_64-darwin.hash = "sha256-bSN0Otu1KdbZvUVKWu3V0eZv5p+A01b57drz401R/IA=";
    aarch64-darwin.hash = "sha256-YVqY+jIjfP4c7Sia89MZR+hSExlHrhhByUgMLr3bZxM=";
  };

  inherit (import ./v4.14.0.nix) bootstrap;
}
