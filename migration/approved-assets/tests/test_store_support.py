from types import SimpleNamespace as NS
from unittest.mock import Mock, patch

import pytest
from PySide6.QtWidgets import QApplication, QWidget
from folimeld.store_support import OFFER_TOKEN, StoreSupport
from folimeld.support_dialog import SupportDialog


@pytest.fixture
def service():
    app = QApplication.instance() or QApplication([])
    parent = QWidget()
    store = StoreSupport(parent, Mock())
    yield store
    store.timer.stop()
    parent.close()


def operation(result=None, error=None):
    return NS(status=1, get_results=Mock(return_value=result, side_effect=error), close=Mock())


def license(owned):
    return NS(add_on_licenses={'sku': NS(in_app_offer_token=OFFER_TOKEN, is_active=owned)})


def product():
    return NS(in_app_offer_token=OFFER_TOKEN, product_kind='Durable', store_id='store-id',
              price=NS(formatted_price='¥300'))


def test_purchase_requires_verified_license_and_prevents_duplicates(service):
    service.product = product()
    service.context.request_purchase_async.return_value = operation(NS(status=0))
    service.context.get_app_license_async.return_value = operation(license(True))
    service.purchase()
    service.purchase()
    service.context.request_purchase_async.assert_called_once_with('store-id')
    assert not service.owned
    service._poll()
    assert not service.owned
    service._poll()
    assert service.owned and not service.busy


@pytest.mark.parametrize('status,message', [(2, 'support_cancelled'), (3, 'support_error'), (4, 'support_error')])
def test_failed_purchase_never_unlocks(service, status, message):
    service.product = product()
    service.context.request_purchase_async.return_value = operation(NS(status=status))
    service.purchase()
    service._poll()
    assert not service.owned and not service.busy
    assert service.message == message


def test_revoked_license_removes_icon_even_if_catalog_fails(service):
    service.owned = True
    service.context.get_app_license_async.return_value = operation(license(False))
    service.context.get_associated_store_products_async.return_value = operation(error=OSError())
    service.refresh()
    service._poll()
    service._poll()
    assert not service.owned and service.message == 'support_error'


def test_network_failure_does_not_erase_known_ownership(service):
    service.owned = True
    service.context.get_app_license_async.return_value = operation(error=OSError())
    service.refresh()
    service._poll()
    assert service.owned and not service.busy


def test_hresult_zero_is_success_and_store_price_is_displayed(service):
    service._products(NS(extended_error=NS(value=0), products={'id': product()}))
    dialog = SupportDialog(service, lambda key, **kw: kw.get('price', key), service.parent())
    assert dialog.buy.text() == '¥300'
    assert dialog.buy.isEnabled()
    service.busy = True
    service.changed.emit()
    assert not dialog.buy.isEnabled()


def test_unpublished_product_disables_purchase(service):
    service._products(NS(extended_error=NS(value=0), products={}))
    service.purchase()
    service.context.request_purchase_async.assert_not_called()
    assert service.message == 'support_unavailable'


def test_non_store_build_has_no_purchase_menu():
    from folimeld.app import MainWindow
    app = QApplication.instance() or QApplication([])
    with patch('folimeld.app.is_packaged', return_value=False):
        window = MainWindow()
        assert window.support is None
        assert not hasattr(window, 'support_action')
        window.close()
