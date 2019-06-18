//
//  ViewController.swift
//  PowerNapTimer27
//
//  Created by Drew Seeholzer on 6/18/19.
//  Copyright © 2019 Drew Seeholzer. All rights reserved.
//

import UIKit
import UserNotifications

class ViewController: UIViewController {
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var napButton: UIButton!
    
    let timer = MyTimer()
    
    //The UNIQUE identifier for our notification
    // Identifier for
    fileprivate let userNotificationIdentifier = "timerFinishedNotification"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        timer.delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateTimer()
    }
    @IBAction func buttonTapped(_ sender: Any) {
        if timer.isOn {
            timer.stopTimer()
            cancelLocalNotification()
        } else {
            timer.startTimer(5)
            scheduleLocalNotification()
        }
        updateLabel()
        updateButton()
    }
    
    func updateLabel() {
        if timer.isOn {
            timerLabel.text = "\(timer.timeRemaining)"
        } else {
            timerLabel.text = "20:00"
        }
    }
    
    func updateButton() {
        if timer.isOn {
            napButton.setTitle("Cancel Nap", for: .normal)
        } else {
            napButton.setTitle("Start Nap", for: .normal)
        }
    }
    
    func updateTimer() {
        
        //Get all notificatons for out current app from the notification center
        UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
            /*
             var ourNotifications: [UNNotificationRequest] = []
             for request in requests {
                if request.identifier == self.userNotificationIdentifier {
                    ourNotifications.append(request)
                }
             }
             */
            
            //Filter out all notifications that do not have (match) our identifier from our constant
            let ourNotifications = requests.filter { $0.identifier == self.userNotificationIdentifier}
            
            //Get our notification from the array, which should have either 1 or 0 elements inside this array
            guard let timerNotificationRequest = ourNotifications.last,
                // Get the trigger from that request, and cast it as our UNCalenderNotificationTrigger
                // We know it can be a UNCalenderNotification because we created it as such
            let trigger = timerNotificationRequest.trigger as? UNCalendarNotificationTrigger,
                // Then we get the exact date in which the trigger should fire
                // This will give us the exact nanosecond to when the notification was triggered
            let fireDate = trigger.nextTriggerDate() else { return }
            
            // Turn off our timer incase one is still running
            self.timer.stopTimer()
            
            //Turn on the timer and have it correspond to the amount of time between NOW and the next trigger date of the trigger (fireDate)
            self.timer.startTimer(fireDate.timeIntervalSinceNow)
        }
    }

}

extension ViewController: MyTimerDelegate {
    func timerStopped() {
        updateButton()
        updateLabel()
    }
    
    func timerCompleted() {
        updateLabel()
        updateButton()
        //Call the display alert Controller func
        displaySnoozeAlertController()
    }
    
    func timerSecondTicked() {
        updateLabel()
    }
    
}

extension ViewController {
    func displaySnoozeAlertController() {
        let alertController = UIAlertController(title: "Time to wake up!", message: "Get up lazy!", preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Snooze for how many minutes?"
            textField.keyboardType = .numberPad
        }
        
        let snoozeAction = UIAlertAction(title: "Snooze", style: .default) { (_) in
            guard let timeText = alertController.textFields?.first?.text,
                let time = TimeInterval(timeText) else { return }
            
            self.timer.startTimer(time * 60)
            self.scheduleLocalNotification()
            self.updateLabel()
            self.updateButton()
        }
        
        alertController.addAction(snoozeAction)
        
        let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
        
        alertController.addAction(dismissAction)
        
        present(alertController, animated: true, completion: nil)
    }
}

extension ViewController {
    func scheduleLocalNotification() {
        //Create the content for the notification
        //The text and the sound and the badge number
        let notificationContent = UNMutableNotificationContent()
        //Set the features of the Notification content based on what you asked the user permission for
        notificationContent.title = "Wake Up!"
        notificationContent.subtitle = "YOUR ALARM IS FINISHED!?!!?!?!?"
        notificationContent.badge = 1
        notificationContent.sound = .default
        
        //We need to set up when the notification should fire
        guard let timeRemaining = timer.timeRemaining else {return}
        //Get the exact current date, then add however many seconds the timer has remaining to find the "firedate"
        let date = Date(timeInterval: timeRemaining, since: Date())
        
        //Get the Date Components from the fire date (Specifically the minutes and seconds)
        let dateComponents = Calendar.current.dateComponents([.minute, .second], from: date)
        
        // Create a trigger for when the notification should fire (send to the user)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // Create the request for this notification by passing in our identifier constant, the content and the trigger we created above
        let request = UNNotificationRequest(identifier: userNotificationIdentifier, content: notificationContent, trigger: trigger)
        
        // Adding that request to the phones notification center
        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    func cancelLocalNotification() {
        //Removing our notification from the notification center by cancelling the pending request by that notification's identifier.
        UNUserNotificationCenter.current()
        .removePendingNotificationRequests(withIdentifiers: [userNotificationIdentifier])
    }
}
