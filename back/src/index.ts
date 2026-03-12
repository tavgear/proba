import type { Core } from '@strapi/strapi';

export default {
  register(/* { strapi }: { strapi: Core.Strapi } */) {},

  async bootstrap({ strapi }: { strapi: Core.Strapi }) {
    // Разрешаем публичный доступ к API для наших типов данных
    const publicRole = await strapi
      .query('plugin::users-permissions.role')
      .findOne({ where: { type: 'public' } });

    if (publicRole) {
      const permissions = [
        { action: 'api::article.article.find' },
        { action: 'api::article.article.findOne' },
        { action: 'api::page.page.find' },
        { action: 'api::page.page.findOne' },
        { action: 'api::global.global.find' },
      ];

      for (const permission of permissions) {
        const existing = await strapi
          .query('plugin::users-permissions.permission')
          .findOne({
            where: {
              role: publicRole.id,
              action: permission.action,
            },
          });

        if (!existing) {
          await strapi.query('plugin::users-permissions.permission').create({
            data: {
              role: publicRole.id,
              action: permission.action,
            },
          });
        }
      }
    }
  },
};
