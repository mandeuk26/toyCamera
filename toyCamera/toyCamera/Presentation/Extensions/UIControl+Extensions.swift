//
//  UIControl+Extensions.swift
//  toyCamera
//
//  Created by 강현준 on 2021/12/23.
//

import Combine
import UIKit

extension UIControl {
    struct EventPublisher: Publisher {
        typealias Output = Void
        typealias Failure = Never
        
        fileprivate var control: UIControl
        fileprivate var event: Event
        
        func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Void == S.Input {
            
            let subscription = EventSubscription<S>()
            subscription.target = subscriber
            subscriber.receive(subscription: subscription)
            
            self.control.addTarget(
                subscription,
                action: #selector(subscription.trigger),
                for: self.event
            )
        }
        
    }
    
    class EventSubscription<Target: Subscriber>: Subscription where Target.Input == Void {
        
        var target: Target?
        
        func request(_ demand: Subscribers.Demand) {}
        
        func cancel() {
            self.target = nil
        }
        
        @objc func trigger() {
            self.target?.receive(())
        }
    }
}

extension UIControl {
    func publisher(for event: Event) -> AnyPublisher<Void, Never> {
        return EventPublisher(control: self, event: event).eraseToAnyPublisher()
    }
}
