import Combine
import Foundation

/// **Project configuration**
/// - Set *Strict Concurrency Checking* to **Targeted** or **Complete**
/// - When possible set *Swift* to version **6**

@globalActor
actor MyOwnGlobalActor {
    actor ActorType { }
    static let shared = ActorType()
}

final class ContentViewModel: ObservableObject, @unchecked Sendable {
    @MainActor @Published private(set) var showLoading = false
    @MainActor @Published private(set) var timer: Date?

    @MyOwnGlobalActor private var globalActor = false

    private var disposeBag = Set<AnyCancellable>.init()
    private var streamTask: Task<(), any Error>?
    private let converter = Converter()

    deinit {
        print("Deinit of \(self)")
    }
}

// MARK: - Swift Concurrency
extension ContentViewModel {
    @MainActor
    func triggerApiCall() async {
        showLoading = true
        printThread(#function)
        do {
            try await withThrowingDiscardingTaskGroup { [weak self] group in
                group.addTask { [weak self] in
                    try await self?.firstApiCall()
                }
                group.addTask { [weak self] in
                    try await self?.secondApiCall()
                }
                group.addTask { [weak self] in
                    try await self?.secondApiCall()
                }
                group.addTask { [weak self] in
                    try await self?.thirdApiCall()
                }
                group.addTask { [weak self] in
                    try await self?.mainActorMethod()
                }
            }
        } catch {
            print("Error: \(error)")
        }
        showLoading = false
    }

    func mainActorRun() async {
        printThread(#function)
        await MainActor.run {
            printThread(#function)
            showLoading = true
        }
        try? await Task.sleep(for: .seconds(1))
        printThread(#function)
        await MainActor.run {
            printThread(#function)
            showLoading = false
        }
    }

    func taskWithMainActor() {
        printThread(#function)
        Task { @MainActor in
            printThread(#function)
            showLoading = true
            try? await Task.sleep(for: .seconds(1))
            printThread(#function)
            showLoading = false
        }
    }

    @MainActor
    func combineWithMainActor() {
        printThread(#function)
        showLoading = true
        let publisher = [1,2,3,4,5].publisher
        publisher
            .receive(on: DispatchQueue.global())
            .print("receiveOn isMainThread: \(Thread.isMainThread), currentThread: \(Thread.current)")
            .delay(for: .seconds(1), scheduler: DispatchQueue.global())
            .receive(on: DispatchQueue.main) // Have to switch back to main queue otherwise I get runtime warning
            .sink { [weak self] values in
                self?.printThread("sink")
                self?.showLoading = false
            }
            .store(in: &disposeBag)
    }

    func ownGlobalActorOne() {
        printThread(#function)
        Task { @MyOwnGlobalActor in
            try? await Task.sleep(for: .seconds(1))
            printThread(#function)
            globalActor = true
        }
        printThread(#function)
    }

    @MyOwnGlobalActor
    func ownGlobalActorTwo() {
        printThread(#function)
        globalActor = true
        printThread(#function)
    }

    func startAsyncStream() {
        // Task has to be stored in local property and cancelled when view dissappears
        // Otherwise stream is endless and view model is not deallocated
        streamTask = Task {
            let stream = Timer.publish(every: 1, on: .main, in: .default).autoconnect().values
            for try await value in stream {
                await MainActor.run {
                    print("Value: \(value)")
                    timer = value
                }
            }
        }
    }

    func stopStream() {
        streamTask?.cancel()
    }

    private func firstApiCall() async throws {
        try await Task.sleep(for: .seconds(1))
        printThread(#function)
    }

    private func secondApiCall() async throws {
        try await Task.sleep(for: .seconds(1))
        printThread(#function)
    }

    private func thirdApiCall() async throws {
        try await Task.sleep(for: .seconds(1))
        printThread(#function)
    }

    @MainActor
    private func mainActorMethod() async throws {
        try await Task.sleep(for: .seconds(1))
        printThread(#function)
    }

    private func printThread(_ method: String) {
        print("\(method) isMainThread: \(Thread.isMainThread), currentThread: \(Thread.current)")
    }
}

struct Converter: Sendable {
/*
    deinit {
        print("Deinit of \(self)")
    }
*/

    private let value = "123456"

    func perform() {
        print(#function, " with value \(value)")
    }
}

// MARK: - Memmory leak
extension ContentViewModel {
    func performEscapingClosure() {
        DispatchQueue.global().async { [weak self] in
            self?.printThread(#function)
            self?.escapingClosure(closure: self?.converter.perform)
            //self?.escapingClosure { [weak self] in self?.converter.perform() }
        }
    }

    func escapingClosure(closure: (@Sendable() -> Void)?) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
            closure?()
        }
    }

    func ownMethod() {
        print(#function)
    }
}
