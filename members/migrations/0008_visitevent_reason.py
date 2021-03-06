# -*- coding: utf-8 -*-
# Generated by Django 1.10.6 on 2017-08-20 05:22
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('members', '0007_auto_20170807_1720'),
    ]

    operations = [
        migrations.AddField(
            model_name='visitevent',
            name='reason',
            field=models.CharField(blank=True, choices=[('CUR', 'Checking it out'), ('CLS', 'Attending a class'), ('MEM', 'Membership privileges'), ('GST', 'Guest of a member'), ('VOL', 'Volunteering'), ('OTH', 'Other')], default=None, help_text='The reason for a visit. Not used on Departures.', max_length=3, null=True),
        ),
    ]
