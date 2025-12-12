import Foundation
import Testing
@testable import RakutenAnalytics

struct DelayedValue<T> {
    private let queue = DispatchQueue(label: "DelayedQueue")
    private let delaySeconds = 0.1
    
    let value: T
    
    init(_ value: T) {
        self.value = value
    }
    
    func get() -> T {
        queue.sync {
            usleep(useconds_t(delaySeconds * Double(USEC_PER_SEC)))
            return value
        }
    }
}

@Suite("AtomicGetSet property wrapper")
struct AtomicWrapperSpec {
    
    class TestInstance {
        @AtomicGetSet var atomicArray = [String]()
        
        func mutateAtomicArray(_ mutation: (inout [String]) -> Void) {
            _atomicArray.mutate(mutation)
        }
    }
    
    let queueA = DispatchQueue(label: "QueueA")
    let queueB = DispatchQueue(label: "QueueB")
    
    func createInstance() -> TestInstance {
        let instance = TestInstance()
        instance.atomicArray = []
        return instance
    }
    
    @Test("will not crash when two threads access the same value at the same time (get)")
    func testConcurrentGetAccess() {
        let instance = createInstance()
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        dispatchGroup.enter()
        
        queueA.async {
            for _ in (1...1_000_000) {
                _ = instance.atomicArray
            }
            dispatchGroup.leave()
        }
        queueB.async {
            for _ in (1...1_000_000) {
                _ = instance.atomicArray
            }
            dispatchGroup.leave()
        }
        dispatchGroup.wait()
    }
    
    @Test("will not crash when two threads access the same value at the same time (set)")
    func testConcurrentSetAccess() {
        let instance = createInstance()
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        dispatchGroup.enter()
        
        queueA.async {
            let valueToSet = ["1"]
            for _ in (1...1_000_000) {
                instance.atomicArray = valueToSet
            }
            dispatchGroup.leave()
        }
        queueB.async {
            let valueToSet = ["2"]
            for _ in (1...1_000_000) {
                instance.atomicArray = valueToSet
            }
            dispatchGroup.leave()
        }
        dispatchGroup.wait()
    }
    
    @Test("will not crash when one thread writes and the other reads the same value at the same time")
    func testConcurrentReadWriteAccess() {
        let instance = createInstance()
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        dispatchGroup.enter()
        
        queueA.async {
            for _ in (1...1_000_000) {
                _ = instance.atomicArray
            }
            dispatchGroup.leave()
        }
        queueB.async {
            let valueToSet = ["value"]
            for _ in (1...1_000_000) {
                instance.atomicArray = valueToSet
            }
            dispatchGroup.leave()
        }
        dispatchGroup.wait()
    }
    
    @Suite("when using mutating functions")
    struct MutatingFunctionsTests {
        // The tests below simulate a situation when one thread tries to modify the value
        // while the other is using mutating function on the same value. The loop was added to ensure effectiveness
        
        class TestInstance {
            @AtomicGetSet var atomicArray = [String]()
            
            func mutateAtomicArray(_ mutation: (inout [String]) -> Void) {
                _atomicArray.mutate(mutation)
            }
        }
        
        let queueA = DispatchQueue(label: "QueueA")
        let queueB = DispatchQueue(label: "QueueB")
        
        func createInstance() -> TestInstance {
            let instance = TestInstance()
            instance.atomicArray = []
            return instance
        }
        
        @Test("should ensure atomicity when using two concurrent `mutate` functions")
        func testAtomicityWithTwoMutateFunctions() {
            let instance = createInstance()
            for _ in (1...100) {
                let dispatchGroup = DispatchGroup()
                dispatchGroup.enter()
                dispatchGroup.enter()
                
                let queueDispatchCoordinator = DispatchGroup()
                queueDispatchCoordinator.enter()
                queueA.async {
                    instance.mutateAtomicArray {
                        queueDispatchCoordinator.leave()
                        $0.append(DelayedValue("string 1").get())
                    }
                    dispatchGroup.leave()
                }
                queueB.async {
                    queueDispatchCoordinator.wait()
                    instance.mutateAtomicArray { $0.append("string 2") }
                    dispatchGroup.leave()
                }
                dispatchGroup.wait()
            }
            
            let expected = [[String]](repeating: ["string 1", "string 2"], count: 100).flatMap({ $0 })
            #expect(instance.atomicArray.elementsEqual(expected))
        }
        
        @Test("should ensure atomicity when using `mutate` function and setter")
        func testAtomicityWithMutateFunctionAndSetter() {
            let instance = createInstance()
            for _ in (1...100) {
                let dispatchGroup = DispatchGroup()
                dispatchGroup.enter()
                dispatchGroup.enter()
                
                let queueDispatchCoordinator = DispatchGroup()
                queueDispatchCoordinator.enter()
                queueA.async {
                    instance.mutateAtomicArray {
                        queueDispatchCoordinator.leave()
                        $0.append(DelayedValue("string 1").get())
                    }
                    dispatchGroup.leave()
                }
                queueB.async {
                    queueDispatchCoordinator.wait()
                    instance.atomicArray = ["string 2"]
                    dispatchGroup.leave()
                }
                dispatchGroup.wait()
                #expect(instance.atomicArray.elementsEqual(["string 2"]))
            }
        }
        
        @Test("should not expect atomic operation without using `mutate` functions")
        func testNonAtomicOperationWithoutMutateFunctions() {
            let instance = createInstance()
            for _ in (1...100) {
                let dispatchGroup = DispatchGroup()
                dispatchGroup.enter()
                dispatchGroup.enter()
                
                let queueDispatchCoordinator = DispatchGroup()
                queueDispatchCoordinator.enter()
                queueA.async {
                    queueDispatchCoordinator.leave()
                    instance.atomicArray.append(DelayedValue("string 1").get())
                    dispatchGroup.leave()
                }
                queueB.async {
                    queueDispatchCoordinator.wait()
                    instance.atomicArray.append("string 2")
                    dispatchGroup.leave()
                }
                dispatchGroup.wait()
            }
            
            let expected = [[String]](repeating: ["string 1", "string 2"], count: 100).flatMap({ $0 })
            #expect(!instance.atomicArray.elementsEqual(expected))
        }
        
        @Test("should not expect atomic operation without using `mutate` function and setter")
        func testNonAtomicOperationWithoutMutateFunctionAndSetter() {
            let instance = createInstance()
            for _ in (1...100) {
                let dispatchGroup = DispatchGroup()
                dispatchGroup.enter()
                dispatchGroup.enter()
                
                let queueDispatchCoordinator = DispatchGroup()
                queueDispatchCoordinator.enter()
                queueA.async {
                    queueDispatchCoordinator.leave()
                    instance.atomicArray.append(DelayedValue("string 1").get())
                    dispatchGroup.leave()
                }
                queueB.async {
                    queueDispatchCoordinator.wait()
                    instance.atomicArray = ["string 2"]
                    dispatchGroup.leave()
                }
                dispatchGroup.wait()
                #expect(instance.atomicArray.elementsEqual(["string 2", "string 1"]))
            }
        }
    }
}
