//
//  LoginScreen.swift
//  StudyHub
//

import SwiftUI
import UIKit

struct LoginScreen: View {
    @AppStorage("is_logged_in") var isLoggedIn = false
    @State private var showRegister = false

    var body: some View {
        if showRegister {
            RegisterScreen(showRegister: $showRegister)
        } else {
            LoginUIKitWrapper(isLoggedIn: $isLoggedIn, showRegister: $showRegister)
                .ignoresSafeArea()
        }
    }
}

struct LoginUIKitWrapper: UIViewControllerRepresentable {
    @Binding var isLoggedIn: Bool
    @Binding var showRegister: Bool

    func makeUIViewController(context: Context) -> LoginUIKitViewController {
        let vc = LoginUIKitViewController()
        vc.onLoginSuccess = { isLoggedIn = true }
        vc.onRegister = { showRegister = true }
        return vc
    }

    func updateUIViewController(_ uiViewController: LoginUIKitViewController, context: Context) {}
}

class LoginUIKitViewController: UIViewController {

    var onLoginSuccess: (() -> Void)?
    var onRegister: (() -> Void)?

    private let bg      = UIColor.systemBackground
    private let surface = UIColor.secondarySystemBackground
    private let border  = UIColor.separator
    private let accent  = UIColor(named: "AppAccent") ?? UIColor.systemIndigo
    private let textPri = UIColor.label
    private let textSec = UIColor.secondaryLabel
    private let textTer = UIColor.tertiaryLabel

    // MARK: - UI

    private lazy var logoView: UIView = {
        let v = UIView()
        v.backgroundColor = surface
        v.layer.cornerRadius = 16
        v.layer.borderWidth = 1
        v.layer.borderColor = border.cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        let iv = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        iv.image = UIImage(systemName: "graduationcap.fill", withConfiguration: config)
        iv.tintColor = accent
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(iv)
        NSLayoutConstraint.activate([
            iv.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            iv.centerYAnchor.constraint(equalTo: v.centerYAnchor)
        ])
        return v
    }()

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Welcome back"
        l.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        l.textColor = textPri
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Sign in to StudyHub"
        l.font = UIFont.systemFont(ofSize: 15)
        l.textColor = textSec
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var emailField = makeDarkField(placeholder: "Email", secure: false)
    private lazy var passwordField = makeDarkField(placeholder: "Password", secure: true)

    private lazy var forgotBtn: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Forgot password?", for: .normal)
        b.setTitleColor(textSec, for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private lazy var errorLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 13)
        l.textColor = UIColor(red: 1, green: 0.45, blue: 0.45, alpha: 1)
        l.isHidden = true
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var loginBtn: UIButton = {
        let b = UIButton(type: .custom)
        b.setTitle("Sign In", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        b.backgroundColor = accent
        b.layer.cornerRadius = 14
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(loginPressed), for: .touchUpInside)
        b.addTarget(self, action: #selector(btnDown), for: .touchDown)
        b.addTarget(self, action: #selector(btnUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        return b
    }()

    private lazy var dividerRow: UIView = makeDivider()

    private lazy var googleBtn: UIButton = {
        let b = UIButton(type: .custom)
        b.setTitle("Continue with Google", for: .normal)
        b.setTitleColor(textPri, for: .normal)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        b.backgroundColor = surface
        b.layer.cornerRadius = 14
        b.layer.borderWidth = 1
        b.layer.borderColor = border.cgColor
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private lazy var registerBtn: UIButton = {
        let b = UIButton(type: .system)
        let base = "Don't have an account?  "
        let bold = "Sign Up"
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
        b.addTarget(self, action: #selector(registerPressed), for: .touchUpInside)
        return b
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = bg
        setupLayout()
        setupKeyboard()
        animateIn()
    }

    // MARK: - Helpers

    private func makeDarkField(placeholder: String, secure: Bool) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.isSecureTextEntry = secure
        tf.keyboardType = secure ? .default : .emailAddress
        tf.keyboardAppearance = .default
        tf.autocapitalizationType = .none
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
        return tf
    }

    private func makeDivider() -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        let line = UIView()
        line.backgroundColor = border
        line.translatesAutoresizingMaskIntoConstraints = false
        let label = UILabel()
        label.text = "or"
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = textTer
        label.backgroundColor = .systemBackground
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(line)
        container.addSubview(label)
        NSLayoutConstraint.activate([
            line.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            line.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            line.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            line.heightAnchor.constraint(equalToConstant: 1),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            label.widthAnchor.constraint(equalToConstant: 36),
            container.heightAnchor.constraint(equalToConstant: 20),
        ])
        return container
    }

    // MARK: - Layout

    private func setupLayout() {
        [logoView, titleLabel, subtitleLabel,
         emailField, passwordField, forgotBtn,
         errorLabel, loginBtn, dividerRow,
         googleBtn, registerBtn].forEach { view.addSubview($0) }

        NSLayoutConstraint.activate([
            logoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 48),
            logoView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            logoView.widthAnchor.constraint(equalToConstant: 52),
            logoView.heightAnchor.constraint(equalToConstant: 52),

            titleLabel.topAnchor.constraint(equalTo: logoView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),

            emailField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            emailField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            emailField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            emailField.heightAnchor.constraint(equalToConstant: 52),

            passwordField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 12),
            passwordField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            passwordField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            passwordField.heightAnchor.constraint(equalToConstant: 52),

            forgotBtn.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 8),
            forgotBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            errorLabel.topAnchor.constraint(equalTo: forgotBtn.bottomAnchor, constant: 8),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            loginBtn.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 16),
            loginBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            loginBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            loginBtn.heightAnchor.constraint(equalToConstant: 54),

            dividerRow.topAnchor.constraint(equalTo: loginBtn.bottomAnchor, constant: 24),
            dividerRow.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            dividerRow.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            googleBtn.topAnchor.constraint(equalTo: dividerRow.bottomAnchor, constant: 24),
            googleBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            googleBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            googleBtn.heightAnchor.constraint(equalToConstant: 52),

            registerBtn.topAnchor.constraint(equalTo: googleBtn.bottomAnchor, constant: 20),
            registerBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    // MARK: - Animate

    private func animateIn() {
        let items: [UIView] = [logoView, titleLabel, subtitleLabel,
                               emailField, passwordField, forgotBtn,
                               loginBtn, dividerRow, googleBtn, registerBtn]
        items.enumerated().forEach { i, v in
            v.alpha = 0
            v.transform = CGAffineTransform(translationX: 0, y: 20)
            UIView.animate(withDuration: 0.5, delay: Double(i) * 0.045,
                           usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
                v.alpha = 1; v.transform = .identity
            }
        }
    }

    // MARK: - Actions

    @objc private func loginPressed() {
        let email = emailField.text ?? ""
        let password = passwordField.text ?? ""
        guard !email.isEmpty, !password.isEmpty else {
            showError("Please fill in all fields"); shake(loginBtn); return
        }
        setLoading(true)
        AuthService.shared.signIn(email: email, password: password) { result in
            switch result {
            case .success: self.onLoginSuccess?()
            case .failure(let e): self.setLoading(false); self.showError(e.localizedDescription); self.shake(self.loginBtn)
            }
        }
    }

    @objc private func registerPressed() { onRegister?() }
    @objc private func btnDown() {
        UIView.animate(withDuration: 0.1) {
            self.loginBtn.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            self.loginBtn.alpha = 0.85
        }
    }
    @objc private func btnUp() {
        UIView.animate(withDuration: 0.2, delay: 0.2, usingSpringWithDamping: 0.6, initialSpringVelocity: 0) {
            self.loginBtn.transform = .identity; self.loginBtn.alpha = 1
        }
    }

    private func setLoading(_ on: Bool) {
        loginBtn.setTitle(on ? "Signing in..." : "Sign In", for: .normal)
        loginBtn.isEnabled = !on
        loginBtn.alpha = on ? 0.6 : 1
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

    private func setupKeyboard() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKB))
            tap.cancelsTouchesInView = false
            view.addGestureRecognizer(tap)
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKB)))
        NotificationCenter.default.addObserver(self, selector: #selector(kbShow),
            name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(kbHide),
            name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func dismissKB() { view.endEditing(true) }
    @objc private func kbShow(_ n: Notification) {
        guard let f = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        UIView.animate(withDuration: 0.3) { self.view.frame.origin.y = -f.height / 3 }
    }
    @objc private func kbHide(_ n: Notification) {
        UIView.animate(withDuration: 0.3) { self.view.frame.origin.y = 0 }
    }

    deinit { NotificationCenter.default.removeObserver(self) }
}
