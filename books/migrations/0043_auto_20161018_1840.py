# -*- coding: utf-8 -*-
# Generated by Django 1.9.10 on 2016-10-19 01:40
from __future__ import unicode_literals

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('books', '0042_auto_20161010_1421'),
    ]

    operations = [
        migrations.AddField(
            model_name='monetarydonation',
            name='earmark',
            field=models.ForeignKey(blank=True, help_text='The account for which this donation is earmarked.', null=True, on_delete=django.db.models.deletion.SET_NULL, to='books.Account'),
        ),
        migrations.AlterField(
            model_name='sale',
            name='payment_method',
            field=models.CharField(choices=[('$', 'Cash'), ('C', 'Check'), ('S', 'Square'), ('2', '2Checkout'), ('W', 'WePay'), ('P', 'PayPal'), ('G', 'GoFundMe')], default='$', help_text='The payment method used.', max_length=1),
        ),
    ]
