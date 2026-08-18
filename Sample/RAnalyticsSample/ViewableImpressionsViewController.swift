import RakutenAnalytics
import UIKit

final class ViewableImpressionsViewController: UIViewController {
    fileprivate struct ViewableItem: ViewableImpressionTrackable {
        let itemId: String
        let itemTitle: String
        let itemDescription: String?
        let itemCategory: String?
        let itemGenre: String?
        let itemPrice: String?
    }

    /// Table presets use cell reuse. Stress presets build N distinct views so all N stay registered.
    private enum DisplayMode: Equatable {
        case table(rowCount: Int)
        case stressAllRegistered(count: Int)
    }

    private static let tableRowPresets = [20, 50, 100, 200, 1000]
    /// Stress segment counts (after table presets): all views registered, no reuse.
    private static let stressRegistrationCounts = [200, 1000]

    /// Table: 20…1000 (`1k`). Stress: `200+`, `1000+`.
    private static let countSegmentTitles: [String] = {
        let tableTitles = tableRowPresets.map { $0 >= 1000 ? "1k" : "\($0)" }
        let stressTitles = stressRegistrationCounts.map { $0 >= 1000 ? "1k+" : "\($0)+" }
        return tableTitles + stressTitles
    }()

    private static func displayMode(forSegmentIndex index: Int) -> DisplayMode {
        let tableCount = tableRowPresets.count
        if index < tableCount {
            return .table(rowCount: tableRowPresets[index])
        }
        let stressIndex = index - tableCount
        precondition(stressIndex >= 0 && stressIndex < stressRegistrationCounts.count, "segment index out of range")
        return .stressAllRegistered(count: stressRegistrationCounts[stressIndex])
    }

    private let controlsStack = UIStackView()
    private let countSegment = UISegmentedControl(items: ViewableImpressionsViewController.countSegmentTitles)
    private let statsLabel = UILabel()

    private let contentContainer = UIView()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let stressScrollView = UIScrollView()
    private let stressStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let tracker = ViewableImpressionTracker()

    private var items: [ViewableItem] = []
    private var displayMode: DisplayMode = .table(rowCount: 20)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Viewable Impressions"

        tracker.minimumDwellTime = 0.5
        tracker.minimumVisibilityPercentage = 0.5
        tracker.enableTracking()

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Refresh",
            style: .plain,
            target: self,
            action: #selector(refreshTapped)
        )

        setupControls()
        setupContentContainer()
        applyDisplayMode(animated: false)
        updateStatsLabel(lastDurationMs: nil, qualified: nil, reason: "initial")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        triggerDwellRefresh(reason: "viewDidAppear")
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.triggerDwellRefresh(reason: "viewport_size_change")
        }
    }

    private func setupControls() {
        countSegment.selectedSegmentIndex = 0
        countSegment.addTarget(self, action: #selector(countSegmentChanged), for: .valueChanged)

        statsLabel.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        statsLabel.textColor = .label
        statsLabel.numberOfLines = 0
        statsLabel.textAlignment = .left

        controlsStack.axis = .vertical
        controlsStack.spacing = 8
        controlsStack.translatesAutoresizingMaskIntoConstraints = false
        controlsStack.addArrangedSubview(countSegment)
        controlsStack.addArrangedSubview(statsLabel)

        view.addSubview(controlsStack)
        NSLayoutConstraint.activate([
            controlsStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            controlsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            controlsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func setupContentContainer() {
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentContainer)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ViewableItemCell.self, forCellReuseIdentifier: ViewableItemCell.reuseIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 84

        stressScrollView.translatesAutoresizingMaskIntoConstraints = false
        stressScrollView.delegate = self
        stressScrollView.addSubview(stressStackView)

        contentContainer.addSubview(tableView)
        contentContainer.addSubview(stressScrollView)

        NSLayoutConstraint.activate([
            contentContainer.topAnchor.constraint(equalTo: controlsStack.bottomAnchor, constant: 8),
            contentContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            tableView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),

            stressScrollView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            stressScrollView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            stressScrollView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            stressScrollView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),

            stressStackView.topAnchor.constraint(equalTo: stressScrollView.contentLayoutGuide.topAnchor, constant: 8),
            stressStackView.leadingAnchor.constraint(equalTo: stressScrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            stressStackView.trailingAnchor.constraint(equalTo: stressScrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            stressStackView.bottomAnchor.constraint(equalTo: stressScrollView.contentLayoutGuide.bottomAnchor, constant: -8),
            stressStackView.widthAnchor.constraint(equalTo: stressScrollView.frameLayoutGuide.widthAnchor, constant: -32)
        ])
    }

    @objc private func countSegmentChanged() {
        displayMode = Self.displayMode(forSegmentIndex: countSegment.selectedSegmentIndex)
        applyDisplayMode(animated: true)
        triggerDwellRefresh(reason: "preset_changed")
    }

    @objc private func refreshTapped() {
        triggerDwellRefresh(reason: "manual")
    }

    private func applyDisplayMode(animated: Bool) {
        tracker.clearManualTracking()
        stressStackView.arrangedSubviews.forEach { view in
            stressStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        switch displayMode {
        case .table(let rowCount):
            tableView.isHidden = false
            stressScrollView.isHidden = true
            items = Self.makeItems(count: rowCount)
            tableView.reloadData()
            tableView.setContentOffset(.zero, animated: animated)
        case .stressAllRegistered(let count):
            tableView.isHidden = true
            stressScrollView.isHidden = false
            items = Self.makeItems(count: count)
            for (index, item) in items.enumerated() {
                let row = StressRegisteredRowView()
                row.configure(item: item, position: index + 1)
                stressStackView.addArrangedSubview(row)
                tracker.track(view: row.trackingView, item: item, itemPosition: index)
            }
            stressScrollView.setContentOffset(.zero, animated: animated)
        }
    }

    private static func makeItems(count: Int) -> [ViewableItem] {
        (1...count).map { index in
            ViewableItem(
                itemId: "viewable-\(index)",
                itemTitle: "Viewable Item \(index)",
                itemDescription: "Sample",
                itemCategory: "Sample",
                itemGenre: "A",
                itemPrice: "\(index * 10)"
            )
        }
    }

    /// For logging / stats: stress mode = all rows registered; table mode = data source row count (reuse applies).
    private var registeredCountForMetrics: Int {
        switch displayMode {
        case .table:
            return items.count
        case .stressAllRegistered:
            return stressStackView.arrangedSubviews.count
        }
    }

    /// Matches `RowPreset.metricsSecondaryLine` in the SwiftUI sample.
    private var statsSecondaryLine: String {
        switch displayMode {
        case .table:
            return "Data source rows: \(items.count)"
        case .stressAllRegistered:
            return "Registered for refresh: \(registeredCountForMetrics)"
        }
    }

    private func activeScrollView() -> UIScrollView {
        stressScrollView.isHidden ? tableView : stressScrollView
    }

    private func updateStatsLabel(lastDurationMs: Double?, qualified: Int?, reason: String) {
        var lines: [String] = [
            "Last trigger: \(reason)",
            statsSecondaryLine
        ]
        if let lastDurationMs {
            lines.append(String(format: "Last refresh→callback: %.2f ms", lastDurationMs))
        } else {
            lines.append("Last refresh→callback: —")
        }
        if let qualified {
            lines.append("Qualified in last batch: \(qualified)")
        } else {
            lines.append("Qualified in last batch: —")
        }
        statsLabel.text = lines.joined(separator: "\n")
    }
}

extension ViewableImpressionsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ViewableItemCell.reuseIdentifier,
            for: indexPath
        ) as? ViewableItemCell ?? ViewableItemCell(style: .default, reuseIdentifier: ViewableItemCell.reuseIdentifier)
        let item = items[indexPath.row]
        cell.configure(with: item, position: indexPath.row + 1)
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        tracker.track(view: cell.contentView, item: item, itemPosition: indexPath.row)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView === activeScrollView(), !decelerate else { return }
        triggerDwellRefresh(reason: "scroll_end_drag")
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView === activeScrollView() else { return }
        triggerDwellRefresh(reason: "scroll_end_decelerate")
    }
}

private extension ViewableImpressionsViewController {
    func triggerDwellRefresh(reason: String) {
        let start = CFAbsoluteTimeGetCurrent()
        let listSize = registeredCountForMetrics
        let signpostID = ViewableImpressionsSampleMetrics.signposter.makeSignpostID()
        let intervalState = ViewableImpressionsSampleMetrics.signposter.beginInterval("refreshState", id: signpostID)

        tracker.refreshState(viewportView: activeScrollView()) { [weak self] eventParameters in
            ViewableImpressionsSampleMetrics.signposter.endInterval("refreshState", intervalState)

            let elapsedMs = (CFAbsoluteTimeGetCurrent() - start) * 1_000
            let qualified = ViewableImpressionsSampleMetrics.viewableItemCount(in: eventParameters)

            let durationLabel = String(format: "%.2f", elapsedMs)
            ViewableImpressionsSampleMetrics.logger.notice(
                "viewable refresh reason=\(reason, privacy: .public) list_size=\(listSize, privacy: .public) viewable_items_in_batch=\(qualified, privacy: .public) duration_ms=\(durationLabel, privacy: .public)"
            )

            DispatchQueue.main.async { [weak self] in
                self?.updateStatsLabel(lastDurationMs: elapsedMs, qualified: qualified, reason: reason)
            }

            if let eventParameters {
                ViewableImpressionsSampleMetrics.logger.notice(
                    "sample RAT: sending pageVisit with viewable_data count=\(qualified, privacy: .public) (items in this event)"
                )
                RAnalyticsRATTracker.shared()
                    .event(withEventType: RAnalyticsEvent.Name.pageVisitForRAT, parameters: eventParameters)
                    .track()
            } else {
                ViewableImpressionsSampleMetrics.logger.notice(
                    "sample RAT: no pageVisit sent — viewable_data empty (0 viewable impression items)"
                )
            }
        }
    }
}

// MARK: - Stress row (one UIView per item — all stay registered)

private final class StressRegisteredRowView: UIView {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let metaLabel = UILabel()
    private let container = UIView()

    /// View passed to `track(view:item:itemPosition:)` — same hierarchy as table cell content.
    var trackingView: UIView { container }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08)
        container.layer.cornerRadius = 10
        addSubview(container)

        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        metaLabel.font = .systemFont(ofSize: 12)
        metaLabel.textColor = .tertiaryLabel

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, metaLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 76),

            container.topAnchor.constraint(equalTo: topAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),

            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(item: ViewableImpressionsViewController.ViewableItem, position: Int) {
        titleLabel.text = item.itemTitle
        subtitleLabel.text = "ID: \(item.itemId)"
        let category = item.itemCategory ?? "N/A"
        let price = item.itemPrice ?? "N/A"
        metaLabel.text = "Item \(position) • Category: \(category) • Price: \(price)"
    }
}

private final class ViewableItemCell: UITableViewCell {
    static let reuseIdentifier = "ViewableItemCell"

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let metaLabel = UILabel()
    private let container = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with item: ViewableImpressionsViewController.ViewableItem, position: Int) {
        titleLabel.text = item.itemTitle
        subtitleLabel.text = "ID: \(item.itemId)"
        let category = item.itemCategory ?? "N/A"
        let price = item.itemPrice ?? "N/A"
        metaLabel.text = "Item \(position) • Category: \(category) • Price: \(price)"
    }

    private func setup() {
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08)
        container.layer.cornerRadius = 10
        contentView.addSubview(container)

        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        metaLabel.font = .systemFont(ofSize: 12)
        metaLabel.textColor = .tertiaryLabel
        metaLabel.numberOfLines = 1

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, metaLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12)
        ])
    }
}
