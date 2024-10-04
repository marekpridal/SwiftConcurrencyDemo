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
    struct FirstError: Error { }
    struct SecondError: Error { }
    struct ThirdError: Error { }

    @MainActor
    func triggerApiCallSerial() async {
        showLoading = true
        do {
            try await firstApiCall()
            try await secondApiCall()
            try await thirdApiCall()
        } catch {
            print("Error: \(error)")
            switch error {
            case is FirstError:
                print("First error")
            case is SecondError:
                print("Second error")
            default:
                print("Generic error")
            }
        }
        showLoading = false
    }

    @MainActor
    func triggerApiCallInParallel() async {
        showLoading = true
        printThread(#function)
        do {
            try await withThrowingDiscardingTaskGroup { [weak self] group in
                group.addTask { [weak self] in
                    try await self?.secondApiCall()
                }
                group.addTask { [weak self] in
                    try await self?.firstApiCall()
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
        printThread(#function + " Started")
        try await Task.sleep(for: .seconds(0.5))
        printThread(#function + " Done")
        throw FirstError()
    }

    private func secondApiCall() async throws {
        printThread(#function + " Started")
        try await Task.sleep(for: .seconds(1))
        printThread(#function + " Done")
        throw SecondError()
    }

    private func thirdApiCall() async throws {
        printThread(#function + " Started")
        try await Task.sleep(for: .seconds(1.5))
        printThread(#function + " Done")
        throw ThirdError()
    }

    @MainActor
    private func mainActorMethod() async throws {
        printThread(#function + " Started")
        try await Task.sleep(for: .seconds(2))
        printThread(#function + " Done")
    }

    private func printThread(_ method: String) {
        print("\(method) isMainThread: \(Thread.isMainThread), currentThread: \(Thread.current)")
    }
}

// MARK: - Memmory leak
extension ContentViewModel {
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
