# -*- coding: utf-8 -*-
# Generated by Django 1.11.7 on 2017-12-07 03:47
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('members', '0009_auto_20170831_1521'),
    ]

    operations = [
        migrations.AlterField(
            model_name='visitevent',
            name='reason',
            field=models.CharField(blank=True, choices=[('CUR', 'Checking it out'), ('CLS', 'Attending a class'), ('MEM', 'Membership privileges'), ('CLB', 'Club privileges'), ('GST', 'Guest of a member'), ('VOL', 'Volunteering'), ('OTH', 'Other')], default=None, help_text='The reason for a visit. Not used on Departures.', max_length=3, null=True),
        ),
    ]
