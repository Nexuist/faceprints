import ArgumentParser
import Foundation

let VERSION = "1.0.0"

struct Options: ParsableArguments {
  @Argument(help: "The filepath of the input image")
  var input: String
  // TODO: faceprints index
}

@main
struct faceprints: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    abstract: "A command line wrapper over Apple's Vision framework.",
    version: VERSION,
    subcommands: [
      Classify.self
    ],
    defaultSubcommand: Classify.self
  )

}
