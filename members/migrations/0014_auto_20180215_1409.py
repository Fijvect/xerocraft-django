# -*- coding: utf-8 -*-
# Generated by Django 1.11.8 on 2018-02-15 21:09
from __future__ import unicode_literals

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('members', '0013_remove_visitevent_sync1'),
    ]

    operations = [
        migrations.AlterUniqueTogether(
            name='visitevent',
            unique_together=set([]),
        ),
    ]
