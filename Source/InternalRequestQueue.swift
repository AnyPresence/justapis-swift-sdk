//
//  InternalRequestQueue.swift
//  JustApisSwiftSDK
//
//  Created by Andrew Palumbo on 1/7/16.
//  Copyright © 2016 AnyPresence. All rights reserved.
//

import Foundation

///
/// Queue of pending and active requests associated with a gateway
///
internal class InternalRequestQueue {
    
    /// Wrapper for InternalRequest items in the queue
    class QueueItem
    {
        let request:InternalRequest
        let callback:RequestCallback
        var next:QueueItem? = nil
        
        init(request:InternalRequest, callback:RequestCallback?)
        {
            self.request = request

            // Generate an empty callback if needed. Makes later logic cleaner
            self.callback = (callback != nil) ? callback! : { _ in } as RequestCallback
        }
    }

    /// Pointer to the front of the queue
    private var nextPending:QueueItem? = nil

    /// Pointer to the end of the queue
    private var lastPending:QueueItem? = nil
    
    /// Number of items in the queue
    internal var numberPending:Int = 0

    /// Computed property (potentially expensive). FIFO Array of all pending requests
    internal var pendingRequests:[Request] {
        return synchronized(lock: self)
            {
                var pendingRequests = [Request]()
                pendingRequests.reserveCapacity(self.numberPending)
                
                var item = nextPending
                while item != nil
                {
                    pendingRequests.append(item!.request)
                    item = item?.next
                }
                return pendingRequests
        }
    }

    /// Requests that have been pulled from queue, but not yet fulfilled
    private var activeRequests:[InternalRequest:RequestCallback] = [InternalRequest:RequestCallback]()

    internal var numberActive:Int { return activeRequests.count }
    
    /// Adds an item to the back of the queue
    func appendRequest(_ request:InternalRequest, callback:RequestCallback?)
    {
        synchronized(lock: self) {
            // Wrap the request
            let item = QueueItem(request: request, callback: callback)
            
            // If the queue is empty, initialize it
            if (0 == numberPending)
            {
                assert(self.nextPending == nil, "InternalRequestQueue.nextPending should be nil when numberPending=0")
                assert(self.lastPending == nil, "InternalRequestQueue.lastPending should be nil when numberPending=0")
                
                self.nextPending = item
            }
            
            // Add to end of queue
            self.lastPending?.next = item
            
            // Move pointer to end of queue, so that it points to this item
            self.lastPending = item
            
            // Increment our count of pending requests
            numberPending += 1
        }
    }
    
    /// Gets the request from the front of the queue, and prepares it for fulfillment
    func nextRequest() -> InternalRequest?
    {
        return synchronized(lock: self) {
            // Get the next request from the pendingRequests queue
            guard let item = self.nextPending else
            {
                assert(self.numberPending == 0, "InternalRequestQueue.numberPending should be 0 when nextPending=nil")
                assert(self.lastPending == nil, "InternalRequestQueue.lastPending should be 0 when nextPending=nil")
                
                // There is no pending request. Return nil
                return nil
            }
            
            // Remove it from the pendingQueue
            self.nextPending = item.next
            
            // Decrement the numberPending
            self.numberPending -= 1
            
            // Clear lastPending pointer if it pointed to this
            if (self.lastPending?.request == item.request)
            {
                self.lastPending = nil
                
                assert(self.numberPending == 0, "InternalRequestQueue.numberPending should be 0 when lastPending=nil")
                assert(self.nextPending == nil, "InternalRequestQueue.nextPending should be nil when lastPending=nil")
            }
            
            
            // Insert it (or an empty callback) in the activeRequests dictionary
            self.activeRequests[item.request] = item.callback
            
            // return the request
            return item.request
        }
    }

    /// Fulfills a request that's been pulled from the queue
    func fulfillRequest(_ request:InternalRequest, result:RequestResult)
    {
        synchronized(lock: self) {
            // Get any callback for this request and pop it from the activeRequests dictionary
            if let callback = self.activeRequests.removeValue(forKey: request)
            {
                // execute any callback
                callback(result)
            }
        }
    }
    
    /// Removes a request from the pending request queue, if it exists
    func cancelPendingRequest(_ request:InternalRequest) -> Bool
    {
        return synchronized(lock: self) {
            var item = nextPending

            // See if the first item matches
            if (item?.request == request)
            {
                // The provided request was the next pending request
                
                // Move the nextPending pointer to the next item
                nextPending = item?.next
                self.numberPending -= 1
                
                // If it was also lastPending, nil out lastPending
                if (lastPending?.request == request)
                {
                    lastPending = nil
                }
                return true
            }
            
            // Step through queue and see if any subsequent item matches
            while let nextItem = item?.next
            {
                if (nextItem.request == request)
                {
                    // Found the request, on the next item

                    // Splice, by pointing this item's next to the subsequent item (if any)
                    item!.next = nextItem.next
                    self.numberPending -= 1

                    if (item!.next == nil)
                    {
                        // There was nothing after the removed item, move the lastPending pointer
                        lastPending = item
                    }
                    return true
                }

                // Step forward
                item = item!.next
            }
            
            // Never found a match
            return false
        }
    }
}
