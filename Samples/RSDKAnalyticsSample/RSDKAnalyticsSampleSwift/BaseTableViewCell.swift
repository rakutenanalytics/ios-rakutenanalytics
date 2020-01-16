import UIKit

protocol BaseCellDelegate: AnyObject {
    func update(_ dict: [String: Any])
}

@IBDesignable class BaseTableViewCell: UITableViewCell {

    var titleLabel: UILabel = UILabel()

    weak var delegate: BaseCellDelegate?

    var title: String? {
        didSet {
            self.update(title: title)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.setup()
    }

    func setup() {
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.titleLabel)

        let leadingConstraint = NSLayoutConstraint(item: self.titleLabel,
                                                   attribute: .leading,
                                                   relatedBy: .equal,
                                                   toItem: self.contentView,
                                                   attribute: .leading,
                                                   multiplier: 1.0,
                                                   constant: 16.0)
        let verConstraint = NSLayoutConstraint(item: self.titleLabel,
                                               attribute: .centerY,
                                               relatedBy: .equal,
                                               toItem: self.contentView,
                                               attribute: .centerY,
                                               multiplier: 1.0,
                                               constant: 0.0)
        self.contentView.addConstraints([leadingConstraint, verConstraint])
    }

    func update(_ value: Any) {
        self.delegate?.update([self.title!: value])
    }

    func update(title: String?) {
        if let title = title {
            self.titleLabel.text = title
        }
    }
}
