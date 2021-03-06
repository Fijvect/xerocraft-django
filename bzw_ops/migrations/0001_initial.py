# -*- coding: utf-8 -*-
# Generated by Django 1.10.6 on 2017-09-13 18:45
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='TimeBlock',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('start_time', models.TimeField(blank=True, help_text='The time at which the time block begins.', null=True)),
                ('duration', models.DurationField(blank=True, help_text='The duration/length of the time block.', null=True)),
                ('first', models.BooleanField(default=False)),
                ('second', models.BooleanField(default=False)),
                ('third', models.BooleanField(default=False)),
                ('fourth', models.BooleanField(default=False)),
                ('last', models.BooleanField(default=False)),
                ('every', models.BooleanField(default=False)),
                ('monday', models.BooleanField(default=False)),
                ('tuesday', models.BooleanField(default=False)),
                ('wednesday', models.BooleanField(default=False)),
                ('thursday', models.BooleanField(default=False)),
                ('friday', models.BooleanField(default=False)),
                ('saturday', models.BooleanField(default=False)),
                ('sunday', models.BooleanField(default=False)),
            ],
        ),
        migrations.CreateModel(
            name='TimeBlockType',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(help_text='A short name for the time block type.', max_length=32)),
                ('description', models.TextField(help_text='A longer description for the time block type.', max_length=2048)),
            ],
        ),
        migrations.AddField(
            model_name='timeblock',
            name='types',
            field=models.ManyToManyField(to='bzw_ops.TimeBlockType'),
        ),
    ]
