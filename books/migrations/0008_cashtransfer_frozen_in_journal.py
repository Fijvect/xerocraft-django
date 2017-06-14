# -*- coding: utf-8 -*-
# Generated by Django 1.10.6 on 2017-06-14 16:11
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('books', '0007_auto_20170613_1513'),
    ]

    operations = [
        migrations.AddField(
            model_name='cashtransfer',
            name='frozen_in_journal',
            field=models.BooleanField(default=False, help_text='If true, the journal entries for this transaction are frozen and will not be modified.'),
        ),
    ]
