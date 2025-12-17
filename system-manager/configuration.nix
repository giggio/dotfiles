{
  nix = {
    settings = {
      experimental-features = "nix-command flakes";
      build-users-group = "nixbld";
      warn-dirty = false;
    };
  };
}
