#include "pthread_impl.h"

int pthread_mutex_timedlock(pthread_mutex_t *restrict m, const struct timespec *restrict at)
{
	if ((m->_m_type&15) == PTHREAD_MUTEX_NORMAL
	    && !a_cas(&m->_m_lock, 0, EBUSY))
		return 0;

	int r, t, priv = (m->_m_type & 128) ^ 128;

	while ((r=pthread_mutex_trylock(m)) == EBUSY) {
		if (!(r=m->_m_lock) || (r&0x40000000)) continue;
		if ((m->_m_type&3) == PTHREAD_MUTEX_ERRORCHECK
		 && (r&0x1fffffff) == __pthread_self()->tid)
			return EDEADLK;

		a_inc(&m->_m_waiters);
		t = r | 0x80000000;
		a_cas(&m->_m_lock, r, t);
		r = __timedwait(&m->_m_lock, t, CLOCK_REALTIME, at, 0, 0, priv);
		a_dec(&m->_m_waiters);
		if (r && r != EINTR) break;
	}
	return r;
}
