import ArgumentParser
import Foundation

let VERSION = "1.1.2"

struct Options: ParsableArguments {
  @Argument(help: "The filepath of the input image")
  var input: String
}

@main
@available(macOS 13.0, *)
struct faceprints: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    abstract: "A command line wrapper over Apple's Vision framework.",
    version: VERSION,
    subcommands: [
      Classify.self,
      Add.self,
      List.self,
      Remove.self,
      Extract.self,
    ],
    defaultSubcommand: Classify.self
  )

}
