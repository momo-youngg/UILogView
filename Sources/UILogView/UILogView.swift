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
    private weak var selectedLogView: UIView? = nil
    private var selectedLogBody: String? = nil
    private var logs: [Log] = [] {
        didSet {
            let isBottom = self.isLogTableViewScrollAtBottom
            self.logTableView.reloadData()
            if isBottom {
                DispatchQueue.main.async {
                    self.didTapGoDownButton()
                }
            }
        }
    }
    private var filteredLog: [Log] {
        guard let filteredString = filteredString, filteredString.isEmpty == false else {
            return self.logs
        }
        return logs.filter { $0.text.contains(filteredString) }
    }
    private var filteredString: String? = nil {
        didSet {
            self.logTableView.reloadData()
        }
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
    
    private var isLogTableViewScrollAtBottom: Bool {
        let totalScrollViewHeight = self.logTableView.contentSize.height
        let scrollFromTop = self.logTableView.contentOffset.y
        let contentAreaHeight =  self.logTableView.bounds.size.height
        
        return scrollFromTop + contentAreaHeight > totalScrollViewHeight
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
        
        let searchImageView = Self.systemImageView("magnifyingglass", color: self.appearance.iconColor)
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
        searchTextField.addTarget(self, action: #selector(filterTextFieldChanged(textField:)), for: .editingChanged)
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
        
        let goUpButton = self.uiButtonWithImage(systemName: "arrow.up", selector: #selector(didTapGoUpButton))
        let goDownButton = self.uiButtonWithImage(systemName: "arrow.down", selector: #selector(didTapGoDownButton))
        let clearButton = self.uiButtonWithImage(systemName: "clear", selector: #selector(didTapClearButton))
        let copyButton = self.uiButtonWithImage(systemName: "doc.on.doc", selector: #selector(didTapCopyButton))
        let customActionButton: UIView? = {
            if self.appearance.customActionButtonHandler == nil {
                return nil
            } else {
                return self.uiButtonWithImage(systemName: "square.and.pencil", selector: #selector(didTapCustomActionButton))
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
        self.logTableView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
    }
    
    @objc private func didTapGoDownButton() {
        guard self.filteredLog.isEmpty == false else {
            return
        }
        let indexPath = IndexPath(row: self.filteredLog.count-1, section: 0)
        self.logTableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
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
        self.showAlert(message: "All logs copied")
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
        backgroundView.addSubview(alertLabel)
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
    
    private func selectLog(_ log: Log) {
        let selectedLogView = UIView()
        selectedLogView.backgroundColor = self.appearance.backgroundColor
        selectedLogView.frame = CGRect(
            x: .zero,
            y: self.appearance.titleAreaHeight,
            width: self.expandedSize.width,
            height: self.expandedSize.height - self.appearance.titleAreaHeight
        )
        self.expandedView.addSubview(selectedLogView)
        self.selectedLogView = selectedLogView
        
        let topControlAreaView = UIView(
            frame: CGRect(
                origin: .zero,
                size: CGSize(
                    width: self.appearance.expanededWidth,
                    height: self.appearance.topControlAreaHeight
                )
            )
        )
        selectedLogView.addSubview(topControlAreaView)
        
        let gap = (self.appearance.topControlAreaHeight - self.appearance.iconSize) / 2
        let backImageButton = self.uiButtonWithImage(systemName: "arrow.backward", selector: #selector(didTapBackButton))
        topControlAreaView.addSubview(backImageButton)
        backImageButton.frame = CGRect(
            origin: CGPoint(
                x: gap,
                y: gap
            ),
            size: CGSize(
                width: self.appearance.iconSize,
                height: self.appearance.iconSize
            )
        )
        
        let copyImageButton = self.uiButtonWithImage(systemName: "doc.on.doc", selector: #selector(didTapSelectedLogCopyButton))
        topControlAreaView.addSubview(copyImageButton)
        copyImageButton.frame = CGRect(
            origin: CGPoint(
                x: topControlAreaView.bounds.size.width - self.appearance.iconSize - gap,
                y: gap
            ),
            size: CGSize(
                width: self.appearance.iconSize,
                height: self.appearance.iconSize
            )
        )
        
        let logTextLabel = UILabel()
        logTextLabel.font = UIFont.systemFont(ofSize: self.appearance.fontSize)
        logTextLabel.textColor = self.appearance.textColor
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = self.appearance.dateFormat
        let dateText = dateFormatter.string(from: log.date)
        let logBody = "> [\(dateText)] \(log.text)"
        self.selectedLogBody = logBody
        logTextLabel.text = logBody
        logTextLabel.numberOfLines = 0
        selectedLogView.addSubview(logTextLabel)
        logTextLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            logTextLabel.topAnchor.constraint(
                equalTo: selectedLogView.topAnchor,
                constant: topControlAreaView.bounds.height + self.appearance.logCellPadding.top
            ),
            logTextLabel.leadingAnchor.constraint(
                equalTo: selectedLogView.leadingAnchor,
                constant: self.appearance.logCellPadding.left
            ),
            logTextLabel.trailingAnchor.constraint(
                equalTo: selectedLogView.trailingAnchor,
                constant: -self.appearance.logCellPadding.right
            )
        ])
    }
    
    @objc private func didTapSelectedLogCopyButton() {
        UIPasteboard.general.string = self.selectedLogBody
        self.showAlert(message: "Selected log copied")
    }
    
    @objc private func didTapBackButton() {
        self.selectedLogView?.removeFromSuperview()
    }
    
    @objc private func filterTextFieldChanged(textField: UITextField) {
        self.filteredString = textField.text
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
        cell.onSelectLog = { [weak self] log in
            self?.selectLog(log)
        }
        cell.layoutIfNeeded()
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
        var onSelectLog: ((Log) -> Void)? = nil
        private let logTextLabel: UILabel = UILabel()
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            configureView()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
        }
        
        override func layoutSubviews() {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = self.appearance.dateFormat
            let dateText = dateFormatter.string(from: log.date)
            self.logTextLabel.text = "> [\(dateText)] \(log.text)"
            
            self.logTextLabel.textColor = {
                if let textColor = self.appearance.textColorAppearance[self.log.level] {
                    return textColor
                }
                return self.appearance.textColor
            }()
            self.logTextLabel.font = UIFont.systemFont(ofSize: self.appearance.fontSize)
        }
        
        private func configureView() {
            self.logTextLabel.numberOfLines = 1
            self.contentView.addSubview(self.logTextLabel)
            self.logTextLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                self.logTextLabel.topAnchor.constraint(
                    equalTo: self.contentView.topAnchor,
                    constant: self.appearance.logCellPadding.top
                ),
                self.logTextLabel.bottomAnchor.constraint(
                    equalTo: self.contentView.bottomAnchor,
                    constant: -self.appearance.logCellPadding.bottom
                ),
                self.logTextLabel.leadingAnchor.constraint(
                    equalTo: self.contentView.leadingAnchor,
                    constant: self.appearance.logCellPadding.left
                ),
                self.logTextLabel.trailingAnchor.constraint(
                    equalTo: self.contentView.trailingAnchor,
                    constant: -self.appearance.logCellPadding.right
                )
            ])
            
            self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapCell)))
        }
        
        @objc
        private func didTapCell() {
            self.onSelectLog?(self.log)
        }
    }
}

extension UILogView {
    static func systemImage(_ systemName: String, color: UIColor) -> UIImage? {
        UIImage(systemName: systemName)?
            .withTintColor(color, renderingMode: .alwaysOriginal)
    }
    
    static func systemImageView(_ systemName: String, color: UIColor) -> UIImageView {
        return UIImageView(image: self.systemImage(systemName, color: color))
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
    
    private func uiButtonWithImage(systemName: String, selector: Selector) -> UIView {
        let button = UIButton()
        let image = Self.systemImage(systemName, color: self.appearance.iconColor)
        button.setImage(image, for: .normal)
        button.addTarget(self, action: selector, for: .touchUpInside)
        return self.viewWithCenteredContent(button)
    }
}

public struct UILogViewApperance {
    let textColor: UIColor
    let backgroundColor: UIColor
    let titleAreaBackgroundColor: UIColor
    let titleAreaTextColor: UIColor
    let textColorAppearance: [Log.Level: UIColor]

    let fontSize: CGFloat
    let iconColor: UIColor
    let iconSize: CGFloat

    let titleAreaHeight: CGFloat
    let foldedWidth: CGFloat
    let expanededWidth: CGFloat
    
    let borderColor: UIColor
    let borderWidth: CGFloat
    
    let foldedTitle: String
    let expanededTitle: String
    
    let topControlAreaHeight: CGFloat
    let logAreaHeight: CGFloat
    let bottomControlAreaHeight: CGFloat
    let topControlAreaSpacing: CGFloat
    
    let customActionButtonHandler: (([Log]) -> Void)?
    let customActionAlertText: String
    
    let dateFormat: String
    let logCellPadding: UIEdgeInsets
    
    let alertTextColor: UIColor
    let alertBackgroundColor: UIColor
    let alertPadding: CGFloat
    let alertDistanceFromTop: CGFloat
    let alertDismissDuration: Int
    
    public init(
        textColor: UIColor = .green,
        backgroundColor: UIColor = .black,
        titleAreaBackgroundColor: UIColor = .green,
        titleAreaTextColor: UIColor = .black,
        textColorAppearance: [Log.Level: UIColor] = [:],
        fontSize: CGFloat = 10,
        titleAreaHeight: CGFloat = 25,
        iconColor: UIColor = .green,
        foldedWidth: CGFloat = 80,
        expanededWidth: CGFloat = 300,
        borderColor: UIColor = .black,
        borderWidth: CGFloat = 3,
        foldedTitle: String = "Show Logs",
        expanededTitle: String = "Logs (Tap to fold)",
        topControlAreaHeight: CGFloat = 25,
        logAreaHeight: CGFloat = 300,
        bottomControlAreaHeight: CGFloat = 25,
        topControlAreaSpacing: CGFloat = 5,
        customActionButtonHandler: (([Log]) -> Void)? = nil,
        customActionAlertText: String = "Something Happens",
        dateFormat: String = "MM-dd HH:mm:ss.SSS",
        logCellPadding: UIEdgeInsets = UIEdgeInsets(top: 1, left: 3, bottom: 1, right: 3),
        alertTextColor: UIColor = .black,
        alertBackgroundColor: UIColor = .white.withAlphaComponent(0.8)
    ) {
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.titleAreaBackgroundColor = titleAreaBackgroundColor
        self.titleAreaTextColor = titleAreaTextColor
        self.textColorAppearance = textColorAppearance
        self.fontSize = fontSize
        self.iconColor = iconColor
        self.iconSize = 15
        self.titleAreaHeight = titleAreaHeight
        self.foldedWidth = foldedWidth
        self.expanededWidth = expanededWidth
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.foldedTitle = foldedTitle
        self.expanededTitle = expanededTitle
        self.topControlAreaHeight = topControlAreaHeight
        self.logAreaHeight = logAreaHeight
        self.bottomControlAreaHeight = bottomControlAreaHeight
        self.topControlAreaSpacing = topControlAreaSpacing
        self.customActionButtonHandler = customActionButtonHandler
        self.customActionAlertText = customActionAlertText
        self.dateFormat = dateFormat
        self.logCellPadding = logCellPadding
        self.alertTextColor = alertTextColor
        self.alertBackgroundColor = alertBackgroundColor
        self.alertPadding = 5
        self.alertDistanceFromTop = 40
        self.alertDismissDuration = 2
    }
}

public struct Log {
    let level: Level
    let text: String
    let date: Date = Date()
    
    public init(
        level: Level = .middle,
        text: String
    ) {
        self.level = level
        self.text = text
    }
    
    public enum Level {
        case high, middle, low
    }
}
