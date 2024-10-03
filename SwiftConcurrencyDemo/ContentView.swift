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
            Button("Trigger API call") {
                Task {
                    await viewModel.triggerApiCall()
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
