import UIKit
import Combine

public class UILogView: UIView {
    private let appearance: UILogViewApperance
    private let foldedView: UIView = UIView()
    private let expandedView: UIView = UIView()
    private var isExpanded: Bool = false {
        didSet {
            self.setNeedsLayout()
        }
    }
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
    
    private var foldedSize: CGSize {
        CGSize(width: self.appearance.foldedWidth, height: self.appearance.titleAreaHeight)
    }
    
    private var expandedSize: CGSize {
        CGSize(
            width: self.appearance.expanededWidth,
            height: self.appearance.titleAreaHeight +
            self.appearance.topControlAreaHeight +
            self.appearance.logAreaHeight +
            self.appearance.bottomControlAreaHeight
        )
    }
    
    public init(point: CGPoint, appearance: UILogViewApperance = UILogViewApperance()) {
        self.appearance = appearance
        let frame = CGRect(
            origin: point,
            size: CGSize(
                width: appearance.foldedWidth,
                height: appearance.titleAreaHeight
            )
        )
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
        if self.isExpanded {
            self.foldedView.removeFromSuperview()
            self.addSubview(self.expandedView)
            self.frame = CGRect(
                origin: self.frame.origin,
                size: self.expandedSize
            )
            self.expandedView.frame = self.bounds
        } else {
            self.expandedView.removeFromSuperview()
            self.addSubview(self.foldedView)
            self.frame = CGRect(
                origin: self.frame.origin,
                size: self.foldedSize
            )
            self.foldedView.frame = self.bounds
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
                origin: CGPoint(
                    x: .zero,
                    y: self.appearance.titleAreaHeight
                ),
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
        
        self.expandedView.backgroundColor = self.appearance.backgroundColor
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
        
        let searchImageView = self.systemImageView("magnifyingglass")
        topControlAreaView.addSubview(searchImageView)
        searchImageView.frame = CGRect(
            origin: CGPoint(
                x: (self.appearance.topControlAreaHeight - self.appearance.iconSize) / 2,
                y: (self.appearance.topControlAreaHeight - self.appearance.iconSize) / 2
            ),
            size: CGSize(
                width: self.appearance.iconSize,
                height: self.appearance.iconSize
            )
        )
        
        let searchTextField = UITextField()
        searchTextField.font = UIFont.systemFont(ofSize: self.appearance.fontSize)
        searchTextField.tintColor = self.appearance.textColor
        searchTextField.textColor = self.appearance.textColor
        searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Filter",
            attributes: [NSAttributedString.Key.foregroundColor : self.appearance.textColor.withAlphaComponent(0.5)]
        )
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
        self.logTableView.backgroundColor = self.appearance.backgroundColor
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
        logBodyView.addSubview(self.logTableView)
    }
    
    private func configureBottomControlAreaView(to logBodyView: UIView) {
        let bottomControlAreaView = UIView(
            frame: CGRect(
                origin: CGPoint(
                    x: logBodyView.bounds.origin.x,
                    y: logBodyView.bounds.height - self.appearance.bottomControlAreaHeight
                ),
                size: CGSize(
                    width: self.appearance.expanededWidth,
                    height: self.appearance.bottomControlAreaHeight
                )
            )
        )
        logBodyView.addSubview(bottomControlAreaView)
        
        func uiButtonWithImage(systemName: String, selector: Selector) -> UIView {
            let button = UIButton()
            let image = self.systemImage(systemName)
            button.setImage(image, for: .normal)
            button.addTarget(self, action: selector, for: .touchUpInside)
            return self.viewWithCenteredContent(button)
        }
        let goUpButton = uiButtonWithImage(systemName: "arrow.up", selector: #selector(didTapGoUpButton))
        let goDownButton = uiButtonWithImage(systemName: "arrow.down", selector: #selector(didTapGoDownButton))
        let clearButton = uiButtonWithImage(systemName: "clear", selector: #selector(didTapClearButton))
        let copyButton = uiButtonWithImage(systemName: "doc.on.doc", selector: #selector(didTapCopyButton))
        let customActionButton: UIView? = {
            if self.appearance.customActionButtonHandler == nil {
                return nil
            } else {
                return uiButtonWithImage(systemName: "square.and.pencil", selector: #selector(didTapCustomActionButton))
            }
        }()
        let buttons = [goUpButton, goDownButton, clearButton, copyButton, customActionButton].compactMap { $0 }
        let buttonStackView = UIStackView(arrangedSubviews: buttons)
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.alignment = .fill
        bottomControlAreaView.addSubview(buttonStackView)
        buttonStackView.frame = bottomControlAreaView.bounds
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
        titleAreaView.backgroundColor = self.appearance.titleAreaBackgroundColor
        titleAreaView.layer.borderWidth = self.appearance.borderWidth
        titleAreaView.layer.borderColor = self.appearance.borderColor.cgColor
        parentView.addSubview(titleAreaView)
        
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: self.appearance.fontSize)
        titleLabel.text = text
        titleLabel.textColor = self.appearance.titleAreaTextColor
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
        alertLabel.font = UIFont.systemFont(ofSize: self.appearance.fontSize)
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
            self.dateLabel.font = UIFont.systemFont(ofSize: self.appearance.fontSize)
            self.logTextLabel.textColor = self.appearance.textColor
            self.logTextLabel.font = UIFont.systemFont(ofSize: self.appearance.fontSize)
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

extension UILogView {
    private func systemImage(_ systemName: String) -> UIImage? {
        UIImage(systemName: systemName)?
            .withTintColor(self.appearance.iconColor, renderingMode: .alwaysOriginal)
    }
    
    private func systemImageView(_ systemName: String) -> UIImageView {
        return UIImageView(image: self.systemImage(systemName))
    }
    
    private func viewWithCenteredContent(_ targetView: UIView) -> UIView {
        let view = UIView()
        view.addSubview(targetView)
        targetView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            targetView.widthAnchor.constraint(equalToConstant: self.appearance.iconSize),
            targetView.widthAnchor.constraint(equalTo: targetView.heightAnchor),
            targetView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            targetView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        return view
    }
}

public struct UILogViewApperance {
    let titleAreaBackgroundColor: UIColor = .green
    let titleAreaTextColor: UIColor = .black
    
    let textColor: UIColor = .green
    let backgroundColor: UIColor = .black
    let borderColor: UIColor = .black
    let borderWidth: CGFloat = 3
    
    let titleAreaHeight: CGFloat = 25
    let foldedWidth: CGFloat = 80
    let expanededWidth: CGFloat = 300
    
    let foldedTitle: String = "Show Logs"
    let expanededTitle: String = "Logs (Tap to fold)"
    
    let topControlAreaHeight: CGFloat = 30
    let logAreaHeight: CGFloat = 300
    let bottomControlAreaHeight: CGFloat = 30
    let topControlAreaSpacing: CGFloat = 5
    
    let customActionButtonHandler: (([Log]) -> Void)? = nil
    let customActionAlertText: String = "Something Happens"
    let textColorAppearance: [Log.Level: UIColor] = [:]
    
    let dateFormat: String = "yyyy-MM-dd HH:mm:sss"
    
    let alertTextColor: UIColor = .black
    let alertBackgroundColor: UIColor = .white.withAlphaComponent(0.7)
    let alertPadding: CGFloat = 5
    let alertDistanceFromTop: CGFloat = 10
    let alertDismissDuration: Int = 2
    
    let fontSize: CGFloat = 12
    let iconColor: UIColor = .green
    let iconSize: CGFloat = 15
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
