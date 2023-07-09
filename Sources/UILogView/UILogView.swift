import UIKit
import Combine

public class UILogView: UIView {
    private let appearance: UILogViewApperance
    private let foldedView: UIView = UIView()
    private let expandedView: UIView = UIView()
    private var isExpanded: Bool = false
    private let logTableView: UITableView = UITableView()
    
    private var logs: [Log] = [] {
        didSet {
            self.logTableView.reloadData()
        }
    }
    
    private var filteredLog: [Log] {
        guard let filteredString = filteredString else {
            return self.logs
        }
        return logs.filter { $0.text.contains(filteredString) }
    }
    
    private var filteredString: String? = nil {
        didSet {
            self.logTableView.reloadData()
        }
    }
    
    public init(frame: CGRect, appearance: UILogViewApperance = UILogViewApperance()) {
        self.appearance = appearance
        super.init(frame: frame)
        self.configureViews()
    }
    
    required init?(coder: NSCoder) {
        self.appearance = UILogViewApperance()
        super.init(coder: coder)
        self.configureViews()
    }
}

extension UILogView {
    public func send(log: Log) {
        DispatchQueue.main.async {
            self.logs.append(log)
        }
    }
}

extension UILogView {
    public override func layoutSubviews() {
        let isNowExpanded = expandedView.superview == self
        guard isNowExpanded != self.isExpanded else {
            return
        }
        if self.isExpanded {
            self.foldedView.removeFromSuperview()
            self.addSubview(self.expandedView)
        } else {
            self.expandedView.removeFromSuperview()
            self.addSubview(self.foldedView)
        }
    }
    
    // called once only at initializer
    private func configureViews() {
        self.configureFoldedView()
        self.configureExpandedView()
    }
    
    private func configureFoldedView() {
        self.configureTitleLabel(
            to: self.foldedView,
            text: self.appearance.foldedTitle,
            width: self.appearance.foldedWidth,
            height: self.appearance.titleAreaHeight
        )
    }
    
    private func configureExpandedView() {
        self.configureTitleLabel(
            to: self.expandedView,
            text: self.appearance.expanededTitle,
            width: self.appearance.expanededWidth,
            height: self.appearance.titleAreaHeight
        )
        self.configureExpandedBodyView()
    }
    
    private func configureExpandedBodyView() {
        let logBodyView = UIView(
            frame: CGRect(
                origin: .zero,
                size: CGSize(
                    width: self.appearance.expanededWidth,
                    height: (self.appearance.topControlAreaHeight + self.appearance.logAreaHeight + self.appearance.bottomControlAreaHeight)
                )
            )
        )
        logBodyView.backgroundColor = self.appearance.backgroundColor
        logBodyView.layer.borderWidth = self.appearance.borderWidth
        logBodyView.layer.borderColor = self.appearance.borderColor.cgColor
        self.expandedView.addSubview(logBodyView)
        
        self.configureTopControlAreaView(to: logBodyView)
        self.configureLogAreaView(to: logBodyView)
        self.configureBottomControlAreaView(to: logBodyView)
    }
    
    private func configureTopControlAreaView(to logBodyView: UIView) {
        let topControlAreaView = UIView(
            frame: CGRect(
                origin: .zero,
                size: CGSize(
                    width: self.appearance.expanededWidth,
                    height: self.appearance.topControlAreaHeight
                )
            )
        )
        logBodyView.addSubview(topControlAreaView)
        
        let searchImageView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        topControlAreaView.addSubview(searchImageView)
        searchImageView.frame = CGRect(
            origin: .zero,
            size: CGSize(
                width: self.appearance.topControlAreaHeight,
                height: self.appearance.topControlAreaHeight
            )
        )
        
        let searchTextField = UITextField()
        searchTextField.placeholder = "Filter"
        topControlAreaView.addSubview(searchTextField)
        searchTextField.frame = CGRect(
            origin: CGPoint(
                x: self.appearance.topControlAreaHeight,
                y: .zero
            ),
            size: CGSize(
                width: self.appearance.expanededWidth - self.appearance.topControlAreaHeight,
                height: self.appearance.topControlAreaHeight
            )
        )
        
        searchTextField.delegate = self
    }
    
    private func configureLogAreaView(to logBodyView: UIView) {
        self.logTableView.register(
            LogTableViewCell.self,
            forCellReuseIdentifier: String(describing: LogTableViewCell.self)
        )
        self.logTableView.dataSource = self
        self.logTableView.delegate = self
        self.logTableView.frame = CGRect(
            origin: CGPoint(
                x: .zero,
                y: self.appearance.topControlAreaHeight
            ),
            size: CGSize(
                width: self.appearance.expanededWidth,
                height: self.appearance.logAreaHeight
            )
        )
        self.addSubview(self.logTableView)
    }
    
    private func configureBottomControlAreaView(to logBodyView: UIView) {
        let bottomControlAreaView = UIView(
            frame: CGRect(
                origin: CGPoint(
                    x: .zero,
                    y: self.appearance.topControlAreaHeight + self.appearance.logAreaHeight
                ),
                size: CGSize(
                    width: self.appearance.expanededWidth,
                    height: self.appearance.bottomControlAreaHeight
                )
            )
        )
        logBodyView.addSubview(bottomControlAreaView)
        
        func uiButtonWithImage(systemName: String, selector: Selector) -> UIButton {
            let button = UIButton()
            let image = UIImage(systemName: systemName)
            button.setImage(image, for: .normal)
            button.addTarget(self, action: selector, for: .touchUpInside)
            return button
        }
        let goUpButton = uiButtonWithImage(systemName: "arrow.up", selector: #selector(didTapGoUpButton))
        let goDownButton = uiButtonWithImage(systemName: "arrow.down", selector: #selector(didTapGoDownButton))
        let clearButton = uiButtonWithImage(systemName: "xmark", selector: #selector(didTapClearButton))
        let copyButton = uiButtonWithImage(systemName: "doc.on.doc", selector: #selector(didTapCopyButton))
        let customActionButton: UIButton? = {
            if self.appearance.customActionButtonHandler == nil {
                return nil
            } else {
                return uiButtonWithImage(systemName: "square.and.pencil", selector: #selector(didTapCustomActionButton))
            }
        }()
        let buttons = [goUpButton, goDownButton, clearButton, copyButton, customActionButton].compactMap { $0 }
        let buttonStackView = UIStackView(arrangedSubviews: buttons)
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .equalSpacing
        buttonStackView.alignment = .fill
        bottomControlAreaView.addSubview(buttonStackView)
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonStackView.leadingAnchor.constraint(equalTo: bottomControlAreaView.leadingAnchor),
            buttonStackView.topAnchor.constraint(equalTo: bottomControlAreaView.topAnchor),
            buttonStackView.bottomAnchor.constraint(equalTo: bottomControlAreaView.bottomAnchor),
            buttonStackView.trailingAnchor.constraint(equalTo: bottomControlAreaView.trailingAnchor)
        ])
    }
    
    private func configureTitleLabel(to parentView: UIView, text: String, width: CGFloat, height: CGFloat) {
        let titleAreaView = UIView(
            frame: CGRect(
                origin: .zero,
                size: CGSize(
                    width: width,
                    height: height
                )
            )
        )
        titleAreaView.backgroundColor = self.appearance.backgroundColor
        titleAreaView.layer.borderWidth = self.appearance.borderWidth
        titleAreaView.layer.borderColor = self.appearance.borderColor.cgColor
        parentView.addSubview(titleAreaView)
        
        let titleLabel = UILabel()
        titleLabel.text = text
        titleLabel.textColor = self.appearance.textColor
        titleAreaView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: titleAreaView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: titleAreaView.centerYAnchor)
        ])
        
        titleAreaView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.didTapTitleView)))
    }
}

extension UILogView {
    @objc private func didTapTitleView() {
        self.isExpanded.toggle()
        self.setNeedsLayout()
    }
    
    @objc private func didTapGoUpButton() {
        self.logTableView.scrollToRow(
            at: IndexPath(index: .zero),
            at: .top,
            animated: true
        )
    }
    
    @objc private func didTapGoDownButton() {
        self.logTableView.scrollToRow(
            at: IndexPath(index: self.filteredLog.count - 1),
            at: .bottom,
            animated: true
        )
    }
    
    @objc private func didTapClearButton() {
        self.logs.removeAll()
    }
    
    @objc private func didTapCopyButton() {
        let joinedLogsString = self.logs.map { log in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = self.appearance.dateFormat
            let formattedDate = dateFormatter.string(from: log.date)
            return "\(formattedDate) \(log.text)"
        }
            .joined(separator: "\n")
        UIPasteboard.general.string = joinedLogsString
        self.showAlert(message: "Copied all logs")
    }
    
    @objc private func didTapCustomActionButton() {
        self.appearance.customActionButtonHandler?(self.logs)
        self.showAlert(message: self.appearance.customActionAlertText)
    }
    
    private func showAlert(message: String) {
        let alertLabel = UILabel()
        alertLabel.text = message
        alertLabel.textColor = self.appearance.alertTextColor
        
        let backgroundView = UIView()
        alertLabel.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = self.appearance.alertBackgroundColor
        NSLayoutConstraint.activate([
            alertLabel.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: self.appearance.alertPadding),
            alertLabel.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: self.appearance.alertPadding),
            alertLabel.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -self.appearance.alertPadding),
            alertLabel.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -self.appearance.alertPadding)
        ])
        
        self.expandedView.addSubview(backgroundView)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(
                equalTo: self.expandedView.topAnchor,
                constant: self.appearance.titleAreaHeight + self.appearance.alertDistanceFromTop
            ),
            backgroundView.centerXAnchor.constraint(equalTo: self.expandedView.centerXAnchor)
        ])
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(self.appearance.alertDismissDuration)) {
            backgroundView.removeFromSuperview()
        }
    }
    
    private func copyLog(_ log: Log) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = self.appearance.dateFormat
        let formattedDate = dateFormatter.string(from: log.date)
        UIPasteboard.general.string = "\(formattedDate) \(log.text)"
        self.showAlert(message: "Copied selected log")
    }
}

extension UILogView: UITextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.filteredString = textField.text
        return true
    }
}

extension UILogView: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredLog.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: LogTableViewCell.self)) as? LogTableViewCell else {
            return UITableViewCell()
        }
        if indexPath.row >= self.logs.count {
            return UITableViewCell()
        }
        let log = self.filteredLog[indexPath.row]
        cell.log = log
        cell.appearance = self.appearance
        cell.longPressHandler = { self.copyLog($0) }
        return cell
    }
}

extension UILogView: UITableViewDelegate {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}

extension UILogView {
    private class LogTableViewCell: UITableViewCell {
        var log: Log = Log(text: "")
        var appearance: UILogViewApperance = UILogViewApperance()
        var longPressHandler: ((Log) -> Void)? = nil
        private var isExpanded = false
        private var isConfigured: Bool = false
        
        private let foldedDelimiterImage: UIImage? = UIImage(systemName: "greaterthan")
        private let expandedDelimiterImage: UIImage? = UIImage(systemName: "chevron.down")
        private let delimiterImageView: UIImageView = UIImageView()
        private let dateLabel: UILabel = UILabel()
        private let logTextLabel: UILabel = UILabel()
        
        override func layoutSubviews() {
            if self.isConfigured == false {
                self.configureView()
                self.isConfigured = true
            }
            
            if self.isExpanded {
                self.delimiterImageView.image = self.expandedDelimiterImage
                self.logTextLabel.numberOfLines = 0
            } else {
                self.delimiterImageView.image = self.foldedDelimiterImage
                self.logTextLabel.numberOfLines = 1
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = self.appearance.dateFormat
            self.dateLabel.text = dateFormatter.string(from: log.date)
            self.logTextLabel.text = log.text
            
            self.dateLabel.textColor = self.appearance.textColor
            self.logTextLabel.textColor = self.appearance.textColor
        }
        
        private func configureView() {
            let stackView = UIStackView(arrangedSubviews: [self.delimiterImageView, self.dateLabel, self.logTextLabel])
            stackView.axis = .horizontal
            stackView.alignment = .top
            stackView.distribution = .fill
            
            self.addSubview(stackView)
            stackView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: self.topAnchor),
                stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
                stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
            ])
            
            self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapCell)))
            self.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(didLogPressCell)))
        }
        
        override func prepareForReuse() {
            self.isExpanded = false
        }
        
        @objc
        private func didTapCell() {
            self.isExpanded.toggle()
            self.setNeedsLayout()
        }
        
        @objc
        private func didLogPressCell() {
            self.longPressHandler?(self.log)
        }
    }
}

public struct UILogViewApperance {
    let textColor: UIColor = .green
    let backgroundColor: UIColor = .black
    let borderColor: UIColor = .black
    let borderWidth: CGFloat = 2
    
    let titleAreaHeight: CGFloat = 30
    let foldedWidth: CGFloat = 60
    let expanededWidth: CGFloat = 200
    
    let foldedTitle: String = "Show Logs"
    let expanededTitle: String = "Logs"
    
    let topControlAreaHeight: CGFloat = 40
    let logAreaHeight: CGFloat = 200
    let bottomControlAreaHeight: CGFloat = 40
    
    let customActionButtonHandler: (([Log]) -> Void)? = nil
    let customActionAlertText: String = "Something Happens"
    let textColorAppearance: [Log.Level: UIColor] = [:]
    
    let dateFormat: String = "yyyy-MM-dd HH:mm:sss"
    
    let alertTextColor: UIColor = .black
    let alertBackgroundColor: UIColor = .white.withAlphaComponent(0.7)
    let alertPadding: CGFloat = 5
    let alertDistanceFromTop: CGFloat = 10
    let alertDismissDuration: Int = 2
    public init() { }
}

public struct Log {
    let level: Level = .middle
    let text: String
    let date: Date = Date()
    
    public enum Level {
        case high, middle, low
    }
}
