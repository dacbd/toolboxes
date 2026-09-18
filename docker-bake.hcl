target "debug" {
  context = "./debug"
  dockerfile = "Dockerfile"
}

target "agents" {
  context = "./agents"
  dockerfile = "Dockerfile"
  contexts = {
    debug-base = "target:debug"
  }
}
