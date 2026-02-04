import Foundation

protocol ViewableImpressionTrackState: AnyObject {
    var item: ViewableImpressionTrackable { get }
    var itemPosition: Int { get }
    var isVisible: Bool { get set }
    var firstVisibleTime: Date { get set }
    var hasTriggered: Bool { get set }
    var visibilityPercentage: Double { get set }
    var screenName: String? { get }
}

final class ViewableImpressionStateAdapter: ViewableImpressionTrackState {
    let item: ViewableImpressionTrackable
    let itemPosition: Int
    let screenName: String?

    private let getIsVisible: () -> Bool
    private let setIsVisible: (Bool) -> Void
    private let getFirstVisibleTime: () -> Date
    private let setFirstVisibleTime: (Date) -> Void
    private let getHasTriggered: () -> Bool
    private let setHasTriggered: (Bool) -> Void
    private let getVisibilityPercentage: () -> Double
    private let setVisibilityPercentage: (Double) -> Void

    init(item: ViewableImpressionTrackable,
         itemPosition: Int,
         screenName: String?,
         getIsVisible: @escaping () -> Bool,
         setIsVisible: @escaping (Bool) -> Void,
         getFirstVisibleTime: @escaping () -> Date,
         setFirstVisibleTime: @escaping (Date) -> Void,
         getHasTriggered: @escaping () -> Bool,
         setHasTriggered: @escaping (Bool) -> Void,
         getVisibilityPercentage: @escaping () -> Double,
         setVisibilityPercentage: @escaping (Double) -> Void) {
        self.item = item
        self.itemPosition = itemPosition
        self.screenName = screenName
        self.getIsVisible = getIsVisible
        self.setIsVisible = setIsVisible
        self.getFirstVisibleTime = getFirstVisibleTime
        self.setFirstVisibleTime = setFirstVisibleTime
        self.getHasTriggered = getHasTriggered
        self.setHasTriggered = setHasTriggered
        self.getVisibilityPercentage = getVisibilityPercentage
        self.setVisibilityPercentage = setVisibilityPercentage
    }

    var isVisible: Bool {
        get { getIsVisible() }
        set { setIsVisible(newValue) }
    }

    var firstVisibleTime: Date {
        get { getFirstVisibleTime() }
        set { setFirstVisibleTime(newValue) }
    }

    var hasTriggered: Bool {
        get { getHasTriggered() }
        set { setHasTriggered(newValue) }
    }

    var visibilityPercentage: Double {
        get { getVisibilityPercentage() }
        set { setVisibilityPercentage(newValue) }
    }
}

struct ViewableImpressionQualifiedItemData {
    let item: ViewableImpressionTrackable
    let dwellTime: TimeInterval
    let visibilityPercentage: Double
    let itemPosition: Int
    let screenName: String?
}

