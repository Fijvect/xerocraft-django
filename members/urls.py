from django.conf.urls import url, include
from . import views
from .restapi import views as restviews
from rest_framework import routers

app_name = "members"  # This is the app namespace not the app name.

router = routers.DefaultRouter()
router.register(r'members', restviews.MemberViewSet)
router.register(r'memberships', restviews.MembershipViewSet)
router.register(r'discovery-methods', restviews.DiscoveryMethodViewSet)
router.register(r'gift-card-refs', restviews.MembershipGiftCardReferenceViewSet)
router.register(r'visit-events', restviews.VisitEventViewSet)

urlpatterns = [

    # For reception desk kiosk (check-in, sign-up, etc):

    url(r'^reception/$',
        views.reception_kiosk_spa,
        name="reception-kiosk"),

    url(r'^reception/(?P<time_shift>[-0-9]+)/$',  # specify shift in seconds
        views.reception_kiosk_spa,
        name="reception-kiosk-timeshift"),

    url(r'^reception/add-discovery-method/$',
        views.reception_kiosk_add_discovery_method,
        name="reception-kiosk-add-discovery-method"),

    url(r'^reception/set-is-adult/$',
        views.reception_kiosk_set_is_adult,
        name="reception-kiosk-set-is-adult"),

    url(r'^reception/email-mship-buy-info/$',
        views.reception_kiosk_email_mship_buy_info,
        name="email-mship-buy-info"),

    # For desktop:
    # TODO: QR coded membership cards are no longer used.
    # TODO: Delete create-card and create-card-download.
    url(r'^create-card/$', views.create_card, name='create-card'),
    url(r'^create-card-download/$', views.create_card_download, name='create-card-download'),
    url(r'^desktop/member-tags/$', views.member_tags, name='desktop-member-tags'),
    url(r'^desktop/member-tags/(?P<member_pk>[0-9]+)(?P<op>[+-])(?P<tag_pk>[0-9]+)/$', views.member_tags, name='desktop-member-tags'),
    url(r'^desktop/member-count-vs-date/$', views.desktop_member_count_vs_date, name='desktop-member-count-vs-date'),

    # For mobile apps:
    # TODO: Mobile app is not currently used.
    # TODO: Verify that these URLs are not used elsewhere, then delete them.
    # TODO: Revise mobile app to use the REST API instead.
    url(r'^api/member-details/(?P<member_card_str>[-_a-zA-Z0-9]{32})_(?P<staff_card_str>[-_a-zA-Z0-9]{32})/$', views.api_member_details, name="api-member-details"),
    url(r'^api/member-details-pub/(?P<member_card_str>[-_a-zA-Z0-9]{32})/$', views.api_member_details_pub, name="api-member-details-pub"),
    url(r'^api/visit-event/(?P<member_card_str>[-_a-zA-Z0-9]{32})_(?P<event_type>[APD])/$', views.api_log_visit_event, name="api-visit-event"),

    # DJANGO REST FRAMEWORK API (AKA "XisApi")
    url(r'^api/', include(router.urls)),
    url(r'^api-authenticate/', views.api_authenticate, name='api-authenticate'),

    # RFID cards
    url(r'^rfid-entry-requested/(?P<rfid_cardnum>[0-9]{1,32})/$', views.rfid_entry_requested, name='rfid-entry-requested'),
    url(r'^rfid-entry-granted/(?P<rfid_cardnum>[0-9]{1,32})/$', views.rfid_entry_granted, name='rfid-entry-granted'),
    url(r'^rfid-entry-denied/(?P<rfid_cardnum>[0-9]{1,32})/$', views.rfid_entry_denied, name='rfid-entry-denied'),
]
