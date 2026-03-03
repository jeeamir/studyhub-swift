//
//  RegisterScreen.swift
//  StudyHub
//

import SwiftUI
import UIKit

struct RegisterScreen: View {
    @AppStorage("is_logged_in") var isLoggedIn = false
    @Binding var showRegister: Bool

    var body: some View {
        RegisterUIKitWrapper(isLoggedIn: $isLoggedIn, showRegister: $showRegister)
            .ignoresSafeArea()
    }
}

struct RegisterUIKitWrapper: UIViewControllerRepresentable {
    @Binding var isLoggedIn: Bool
    @Binding var showRegister: Bool

    func makeUIViewController(context: Context) -> RegisterUIKitViewController {
        let vc = RegisterUIKitViewController()
        vc.onRegisterSuccess = { isLoggedIn = true }
        vc.onBack = { showRegister = false }
        return vc
    }

    func updateUIViewController(_ uiViewController: RegisterUIKitViewController, context: Context) {}
}

class RegisterUIKitViewController: UIViewController {

    var onRegisterSuccess: (() -> Void)?
    var onBack: (() -> Void)?
    
    private var universities: [University] = []

    
    private let bg      = UIColor.systemBackground
    private let surface = UIColor.secondarySystemBackground
    private let border  = UIColor.separator
    private let accent  = UIColor(named: "AppAccent") ?? UIColor.systemIndigo
    private let textPri = UIColor.label
    private let textSec = UIColor.secondaryLabel
    private let textTer = UIColor.tertiaryLabel

    // MARK: - UI

    private lazy var backBtn: UIButton = {
        let b = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        b.setImage(UIImage(systemName: "arrow.left", withConfiguration: config), for: .normal)
        b.tintColor = textPri
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(backPressed), for: .touchUpInside)
        return b
    }()

    private lazy var stepBar: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        let steps: [(CGFloat, Bool)] = [(28, true), (8, false), (8, false)]
        var prev: UIView? = nil
        for (width, active) in steps {
            let dot = UIView()
            dot.backgroundColor = active ? accent : UIColor(red: 1, green: 1, blue: 1, alpha: 0.12)
            dot.layer.cornerRadius = 2
            dot.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(dot)
            NSLayoutConstraint.activate([
                dot.topAnchor.constraint(equalTo: container.topAnchor),
                dot.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                dot.heightAnchor.constraint(equalToConstant: 4),
                dot.widthAnchor.constraint(equalToConstant: width),
            ])
            if let prev = prev {
                dot.leadingAnchor.constraint(equalTo: prev.trailingAnchor, constant: 4).isActive = true
            } else {
                dot.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
            }
            prev = dot
        }
        if let last = container.subviews.last {
            last.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        }
        return container
    }()

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Create your\naccount"
        l.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        l.textColor = textPri
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Join StudyHub at Narxoz University"
        l.font = UIFont.systemFont(ofSize: 15)
        l.textColor = textSec
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    lazy var nameField    = makeDarkField(placeholder: "Full Name", secure: false, keyboard: .default)
    lazy var emailField   = makeDarkField(placeholder: "University Email", secure: false, keyboard: .emailAddress)
    lazy var passwordField = makeDarkField(placeholder: "Password (min 6 characters)", secure: true, keyboard: .default)

    private lazy var errorLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 13)
        l.textColor = UIColor(red: 1, green: 0.45, blue: 0.45, alpha: 1)
        l.isHidden = true
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var registerBtn: UIButton = {
        let b = UIButton(type: .custom)
        b.setTitle("Create Account", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        b.backgroundColor = accent
        b.layer.cornerRadius = 14
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(registerPressed), for: .touchUpInside)
        b.addTarget(self, action: #selector(btnDown), for: .touchDown)
        b.addTarget(self, action: #selector(btnUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        return b
    }()

    private lazy var termsLabel: UILabel = {
        let l = UILabel()
        let text = "By continuing you agree to our Terms of Service and Privacy Policy"
        let attr = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: text.count)
        attr.addAttribute(.foregroundColor, value: textTer, range: fullRange)
        attr.addAttribute(.font, value: UIFont.systemFont(ofSize: 11), range: fullRange)
        for keyword in ["Terms of Service", "Privacy Policy"] {
            let range = (text as NSString).range(of: keyword)
            attr.addAttribute(.foregroundColor, value: textSec, range: range)
        }
        l.attributedText = attr
        l.numberOfLines = 2
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var signInBtn: UIButton = {
        let b = UIButton(type: .system)
        let base = "Already have an account?  "
        let bold = "Sign In"
        let attr = NSMutableAttributedString(string: base + bold)
        attr.addAttribute(.foregroundColor, value: textSec,
                          range: NSRange(location: 0, length: base.count))
        attr.addAttribute(.foregroundColor, value: accent,
                          range: NSRange(location: base.count, length: bold.count))
        attr.addAttribute(.font, value: UIFont.systemFont(ofSize: 14),
                          range: NSRange(location: 0, length: base.count))
        attr.addAttribute(.font, value: UIFont.systemFont(ofSize: 14, weight: .semibold),
                          range: NSRange(location: base.count, length: bold.count))
        b.setAttributedTitle(attr, for: .normal)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(backPressed), for: .touchUpInside)
        return b
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = bg
        setupLayout()
        setupKeyboardDismiss()
        setupKeyboardObservers()
        loadUniversities()
        nameField.delegate = self
        emailField.delegate = self
        passwordField.delegate = self
    }
    
    private func loadUniversities() {
        SupabaseService.shared.getUniversities { result in
            if case .success(let data) = result {
                self.universities = data
            }
        }
    }


    // MARK: - Helpers

    private func makeDarkField(placeholder: String, secure: Bool,
                               keyboard: UIKeyboardType) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.isSecureTextEntry = secure
        tf.keyboardType = keyboard
        tf.keyboardAppearance = .default
        tf.autocapitalizationType = secure ? .none : (keyboard == .default ? .words : .none)
        tf.autocorrectionType = .no
        tf.backgroundColor = surface
        tf.layer.cornerRadius = 14
        tf.layer.borderWidth = 1
        tf.layer.borderColor = border.cgColor
        tf.textColor = textPri
        tf.tintColor = accent
        tf.font = UIFont.systemFont(ofSize: 15)
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 18, height: 0))
        tf.leftViewMode = .always
        tf.attributedPlaceholder = NSAttributedString(string: placeholder,
            attributes: [.foregroundColor: textTer])
        tf.translatesAutoresizingMaskIntoConstraints = false
        if secure {
            tf.textContentType = .oneTimeCode
            tf.passwordRules = nil
        }
        return tf
    }

    // MARK: - Layout

    private func setupLayout() {
        [backBtn, stepBar, titleLabel, subtitleLabel,
         nameField, emailField, passwordField,
         errorLabel, registerBtn, termsLabel, signInBtn].forEach { view.addSubview($0) }

        NSLayoutConstraint.activate([
            backBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            backBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backBtn.widthAnchor.constraint(equalToConstant: 36),
            backBtn.heightAnchor.constraint(equalToConstant: 36),

            stepBar.topAnchor.constraint(equalTo: backBtn.bottomAnchor, constant: 24),
            stepBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stepBar.heightAnchor.constraint(equalToConstant: 4),

            titleLabel.topAnchor.constraint(equalTo: stepBar.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),

            nameField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            nameField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            nameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            nameField.heightAnchor.constraint(equalToConstant: 52),

            emailField.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 12),
            emailField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            emailField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            emailField.heightAnchor.constraint(equalToConstant: 52),

            passwordField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 12),
            passwordField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            passwordField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            passwordField.heightAnchor.constraint(equalToConstant: 52),

            errorLabel.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 10),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            registerBtn.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 16),
            registerBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            registerBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            registerBtn.heightAnchor.constraint(equalToConstant: 54),

            termsLabel.topAnchor.constraint(equalTo: registerBtn.bottomAnchor, constant: 14),
            termsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            termsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            signInBtn.topAnchor.constraint(equalTo: termsLabel.bottomAnchor, constant: 16),
            signInBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    // MARK: - Animate

    private func animateIn() {
        let items: [UIView] = [backBtn, stepBar, titleLabel, subtitleLabel,
                               nameField, emailField, passwordField,
                               registerBtn, termsLabel, signInBtn]
        items.enumerated().forEach { i, v in
            v.alpha = 0
            v.transform = CGAffineTransform(translationX: 0, y: 20)
            UIView.animate(withDuration: 0.5, delay: Double(i) * 0.04,
                           usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
                v.alpha = 1; v.transform = .identity
            }
        }
    }

    // MARK: - Actions

    @objc func registerPressed() {
        let name = nameField.text ?? ""
        let email = emailField.text ?? ""
        let password = passwordField.text ?? ""

        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            showError("All fields are required"); shake(registerBtn); return
        }

        guard let university = universityFrom(email: email) else {
            showError("Only university emails supported (@narxoz.kz, @kbtu.kz, etc.)")
            shake(registerBtn); return
        }

        guard password.count >= 6 else {
            showError("Password must be at least 6 characters"); shake(registerBtn); return
        }

        UserDefaults.standard.set(university, forKey: "detected_university")
        setLoading(true)

        AuthService.shared.signUp(email: email, password: password, fullName: name) { result in
            switch result {
            case .success: self.onRegisterSuccess?()
            case .failure(let e): self.setLoading(false); self.showError(e.localizedDescription)
            }
        }
    }

    private func universityFrom(email: String) -> String? {
        let domain = email.lowercased().components(separatedBy: "@").last ?? ""
        return universities.first { $0.domain == domain }?.name
    }

    @objc func backPressed() { onBack?() }

    @objc private func btnDown() {
        UIView.animate(withDuration: 0.1) {
            self.registerBtn.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            self.registerBtn.alpha = 0.85
        }
    }
    @objc private func btnUp() {
        UIView.animate(withDuration: 0.2, delay: 0.2, usingSpringWithDamping: 0.6, initialSpringVelocity: 0) {
            self.registerBtn.transform = .identity; self.registerBtn.alpha = 1
        }
    }

    private func setLoading(_ on: Bool) {
        registerBtn.setTitle(on ? "Creating account..." : "Create Account", for: .normal)
        registerBtn.isEnabled = !on
        registerBtn.alpha = on ? 0.6 : 1
    }

    private func showError(_ msg: String) {
        errorLabel.text = msg; errorLabel.isHidden = false; errorLabel.alpha = 0
        UIView.animate(withDuration: 0.25) { self.errorLabel.alpha = 1 }
    }

    private func shake(_ v: UIView) {
        let a = CAKeyframeAnimation(keyPath: "transform.translation.x")
        a.timingFunction = CAMediaTimingFunction(name: .linear)
        a.duration = 0.4; a.values = [-8, 8, -6, 6, -4, 4, 0]
        v.layer.add(a, forKey: "shake")
    }

    // MARK: - Keyboard

    private func setupKeyboardDismiss() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKB))
            tap.cancelsTouchesInView = false
            view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKB() { view.endEditing(true) }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(kbShow),
            name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(kbHide),
            name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func kbShow(_ n: Notification) {
        guard let f = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        UIView.animate(withDuration: 0.3) { self.view.frame.origin.y = -f.height / 3 }
    }
    @objc private func kbHide(_ n: Notification) {
        UIView.animate(withDuration: 0.3) { self.view.frame.origin.y = 0 }
    }

    deinit { NotificationCenter.default.removeObserver(self) }

}

extension RegisterUIKitViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameField { emailField.becomeFirstResponder() }
        else if textField == emailField { passwordField.becomeFirstResponder() }
        else { textField.resignFirstResponder() }
        return true
    }
}
