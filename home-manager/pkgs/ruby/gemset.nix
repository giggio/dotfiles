{
  language_server-protocol = {
    groups = [ "default" ];
    platforms = [ ];
    source = {
      remotes = [ "https://rubygems.org" ];
      sha256 = "1k0311vah76kg5m6zr7wmkwyk5p2f9d9hyckjpn3xgr83ajkj7px";
      type = "gem";
    };
    version = "3.17.0.5";
  };
  logger = {
    groups = [ "default" ];
    platforms = [ ];
    source = {
      remotes = [ "https://rubygems.org" ];
      sha256 = "00q2zznygpbls8asz5knjvvj2brr3ghmqxgr83xnrdj4rk3xwvhr";
      type = "gem";
    };
    version = "1.7.0";
  };
  prism = {
    groups = [ "default" ];
    platforms = [ ];
    source = {
      remotes = [ "https://rubygems.org" ];
      sha256 = "0gkhpdjib9zi9i27vd9djrxiwjia03cijmd6q8yj2q1ix403w3nw";
      type = "gem";
    };
    version = "1.4.0";
  };
  rbs = {
    dependencies = [ "logger" ];
    groups = [ "default" ];
    platforms = [ ];
    source = {
      remotes = [ "https://rubygems.org" ];
      sha256 = "1mx533jn2nv29xc5faw9g5xj9qbdaiwl9wv2byv98bgw6gqwhhlf";
      type = "gem";
    };
    version = "3.9.4";
  };
  ruby-lsp = {
    dependencies = [
      "language_server-protocol"
      "prism"
      "rbs"
      "sorbet-runtime"
    ];
    groups = [ "default" ];
    platforms = [ ];
    source = {
      remotes = [ "https://rubygems.org" ];
      sha256 = "1cxyg49nhy137hfjprqwb4h29gmpnwb8yif6qza6p6dgavm98p77";
      type = "gem";
    };
    version = "0.24.1";
  };
  sorbet-runtime = {
    groups = [ "default" ];
    platforms = [ ];
    source = {
      remotes = [ "https://rubygems.org" ];
      sha256 = "094jqwg321v79g6i6f6rmd64zi4jlvhyvqghky3b4cxljm77i7yx";
      type = "gem";
    };
    version = "0.5.12157";
  };
}
