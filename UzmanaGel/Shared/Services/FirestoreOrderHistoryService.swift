import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - FirestoreOrderHistoryService
// Reads from the existing 'reservations' collection (customerId, status, etc.)
// and maps them to the app's Order model.

class FirestoreOrderHistoryService: OrderHistoryService {
    private let db = Firestore.firestore()
    
    func fetchOrders() async throws -> [Order] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı girişi yapılmamış."])
        }
        
        let snapshot = try await db.collection("reservations")
            .whereField("customerId", isEqualTo: userId)
            .getDocuments()
        
        // Sort by date descending in Swift to avoid needing a composite Firestore index
        let orders = snapshot.documents.compactMap { document in
            reservationToOrder(document: document)
        }
        return orders.sorted { $0.date > $1.date }
    }
    
    func repeatOrder(orderId: String) async throws -> Order {
        guard Auth.auth().currentUser != nil else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Kullanıcı girişi yapılmamış."])
        }
        
        // Fetch original reservation
        let docRef = db.collection("reservations").document(orderId)
        let docSnap = try await docRef.getDocument()
        guard let data = docSnap.data() else {
            throw NSError(domain: "OrderService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Rezervasyon bulunamadı."])
        }
        
        // Create a new reservation as a repeat
        let newId = UUID().uuidString
        var newData = data
        newData["reservationId"] = newId
        newData["status"] = "pending"
        newData["createdAt"] = Timestamp(date: Date())
        newData["updatedAt"] = Timestamp(date: Date())
        newData["isRated"] = false
        newData["rating"] = NSNull()
        
        try await db.collection("reservations").document(newId).setData(newData)
        
        // Return as Order model
        let tempOrder = Order(
            id: newId,
            providerId: data["providerId"] as? String,
            serviceId: data["serviceId"] as? String,
            providerName: data["providerName"] as? String ?? "",
            serviceTitle: data["serviceTitle"] as? String ?? "",
            price: data["servicePrice"] as? Double ?? 0,
            date: Date(),
            status: .pending,
            rating: nil,
            isRated: false
        )
        return tempOrder
    }
    
    func evaluateOrder(orderId: String, rating: Int, comment: String?) async throws {
        let docRef = db.collection("reservations").document(orderId)
        var updateData: [String: Any] = [
            "isRated": true,
            "rating": rating,
            "updatedAt": Timestamp(date: Date())
        ]
        if let comment = comment {
            updateData["ratingComment"] = comment
        }
        try await docRef.updateData(updateData)
    }
    
    // MARK: - Helper: Convert Firestore reservation document -> Order model
    private func reservationToOrder(document: DocumentSnapshot) -> Order? {
        guard let data = document.data() else { return nil }
        
        let id = document.documentID
        let providerId = data["providerId"] as? String
        let serviceId = data["serviceId"] as? String
        let providerName = data["providerName"] as? String ?? "Bilinmeyen Usta"
        let serviceTitle = data["serviceTitle"] as? String ?? "Bilinmeyen Hizmet"
        let price = data["servicePrice"] as? Double ?? 0
        let statusString = data["status"] as? String ?? "pending"
        let rating = data["rating"] as? Int
        let isRated = data["isRated"] as? Bool ?? false
        
        // Parse date from Firestore Timestamp
        var date = Date()
        if let ts = data["createdAt"] as? Timestamp {
            date = ts.dateValue()
        } else if let ts = data["reservationDate"] as? Timestamp {
            date = ts.dateValue()
        }
        
        // Map status string to Order.OrderStatus
        let status: Order.OrderStatus
        switch statusString {
        case "pending":     status = .pending
        case "accepted", "inProgress": status = .active
        case "completed":   status = .completed
        case "cancelled", "rejected", "noShow": status = .cancelled
        default:            status = .pending
        }
        
        return Order(
            id: id,
            providerId: providerId,
            serviceId: serviceId,
            providerName: providerName,
            serviceTitle: serviceTitle,
            price: price,
            date: date,
            status: status,
            rating: rating,
            isRated: isRated
        )
    }
}
