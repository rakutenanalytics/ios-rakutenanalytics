import UIKit
import RakutenAnalytics

final class ViewableImpressionsViewController: UIViewController {
    fileprivate struct ViewableItem: ViewableImpressionTrackable {
        let itemId: String
        let itemTitle: String
        let itemDescription: String?
        let itemCategory: String?
        let itemGenre: String?
        let itemPrice: String?
    }

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let tracker = ViewableImpressionTracker()
    private let items: [ViewableItem] = (1...20).map { index in
        ViewableItem(
            itemId: "viewable-\(index)",
            itemTitle: "Viewable Item \(index)",
            itemDescription: "Sample",
            itemCategory: "Sample",
            itemGenre: "A",
            itemPrice: "\(index * 10)"
        )
    }

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

        setupTableView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        triggerDwellRefresh()
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ViewableItemCell.self, forCellReuseIdentifier: ViewableItemCell.reuseIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 84
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func refreshTapped() {
        triggerDwellRefresh()
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
        guard !decelerate else { return }
        triggerDwellRefresh()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        triggerDwellRefresh()
    }
}

private extension ViewableImpressionsViewController {
    func triggerDwellRefresh() {
        tracker.refreshState(viewportView: tableView) { eventParameters in
            guard let eventParameters = eventParameters else { return }
            RAnalyticsRATTracker.shared()
                .event(withEventType: RAnalyticsEvent.Name.pageVisitForRAT, parameters: eventParameters)
                .track()
        }
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
