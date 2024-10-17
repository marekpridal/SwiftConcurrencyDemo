import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        VStack {
            ProgressView()
                .opacity(viewModel.showLoading ? 1 : 0)
                .padding()
            if let timer = viewModel.timer {
                Text(timer.formatted(date: .omitted, time: .complete))
                    .contentTransition(.numericText())
            }
            Button("Trigger API call Serial") {
                Task {
                    await viewModel.triggerApiCallSerial()
                }
            }
            Button("Trigger API call in Parallel") {
                Task {
                    await viewModel.triggerApiCallInParallel()
                }
            }
            Button("Main Actor run") {
                Task {
                    await viewModel.mainActorRun()
                }
            }
            Button("Task with Main Actor") {
                viewModel.taskWithMainActor()
            }
            Button("Combine with Main Actor") {
                viewModel.combineWithMainActor()
            }
            Button("Own global actor one") {
                viewModel.ownGlobalActorOne()
            }
            Button("Own global actor two") {
                Task {
                    await viewModel.ownGlobalActorTwo()
                }
            }
            Button("Start stream") {
                viewModel.startAsyncStream()
            }

            Button("Stop stream") {
                viewModel.stopStream()
            }
            Button("Perform escaping closure", action: viewModel.performEscapingClosure)
            Button("Perform Action 1", action: viewModel.performAction1)
            Button("Perform Action 2", action: viewModel.performAction2)
            Button("Perform Action 3", action: viewModel.performAction3)
            Button("Perform Action 4", action: viewModel.performAction4)
            Button("Perform Action 5", action: viewModel.performAction5)
            Button("Perform Action 6", action: viewModel.performAction6)
            Button("Perform Action 7", action: viewModel.performAction7)
            Button("Perform Action 8", action: viewModel.performAction8)
            Button("Perform Action 81", action: viewModel.performAction81)
            Button("Perform Action 9", action: viewModel.performAction9)
            Button("Perform Action 10", action: viewModel.performAction10)
        }
        /*
        .onDisappear {
            viewModel.stopStream()
        }
         */
        .padding()
    }
}

#Preview {
    ContentView()
}
