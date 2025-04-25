// GambleLedger/Common/Utilities/NotificationManager.swift
import Foundation
import UserNotifications
import SwiftUI

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {
        requestPermission()
    }
    
    // 通知権限リクエスト
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    // 予算警告通知
    func scheduleBudgetWarning(percentage: Int, delay: TimeInterval = 0) {
        let content = UNMutableNotificationContent()
        content.title = Constants.Notifications.budgetWarningTitle
        content.body = String(format: Constants.Notifications.budgetWarningBody, percentage)
        content.sound = .default
        
        scheduleNotification(identifier: "budget.warning", content: content, delay: delay)
    }
    
    // 予算危険通知
    func scheduleBudgetDanger(percentage: Int, delay: TimeInterval = 0) {
        let content = UNMutableNotificationContent()
        content.title = Constants.Notifications.budgetDangerTitle
        content.body = String(format: Constants.Notifications.budgetDangerBody, percentage)
        content.sound = .default
        
        scheduleNotification(identifier: "budget.danger", content: content, delay: delay)
    }
    
    // 連敗警告通知
    func scheduleConsecutiveLossWarning(count: Int, delay: TimeInterval = 0) {
        let content = UNMutableNotificationContent()
        content.title = Constants.Notifications.consecutiveLossTitle
        content.body = String(format: Constants.Notifications.consecutiveLossBody, count)
        content.sound = .default
        
        scheduleNotification(identifier: "consecutive.loss", content: content, delay: delay)
    }
    
    // 通知のスケジュール
    private func scheduleNotification(
        identifier: String,
        content: UNNotificationContent,
        delay: TimeInterval
    ) {
        // 既存の同じIDの通知をキャンセル
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [identifier]
        )
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, delay),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
}
