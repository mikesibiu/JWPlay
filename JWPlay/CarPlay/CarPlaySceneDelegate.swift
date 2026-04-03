import CarPlay
import UIKit

final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {

    static weak var interfaceController: CPInterfaceController?
    private var templateProvider: CarPlayTemplateProvider?

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        Self.interfaceController = interfaceController
        let provider = CarPlayTemplateProvider(interfaceController: interfaceController)
        templateProvider = provider
        provider.connect()
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController,
        from window: CPWindow
    ) {
        Self.interfaceController = nil
        templateProvider = nil
    }
}
